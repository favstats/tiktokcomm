# Authentication Functions

#' Authenticate with TikTok Commercial API
#'
#' This function sets up your TikTok Commercial API credentials and authenticates with the API.
#' It stores the client key, secret, and access token in your .Renviron file.
#'
#' @param force Logical. If TRUE, will overwrite existing credentials without asking. Default is FALSE.
#' @param verbose Logical. If TRUE, provides detailed output. Default is FALSE.
#'
#' @return Invisibly returns TRUE if authentication was successful, FALSE otherwise.
#' @export
#'
#' @examples
#' \dontrun{
#' tiktokcomm_auth()
#' }
tiktokcomm_auth <- function(force = FALSE, verbose = FALSE) {
  # Check for existing credentials
  existing_key <- Sys.getenv("TIKTOK_COMM_CLIENT_KEY")
  existing_secret <- Sys.getenv("TIKTOK_COMM_CLIENT_SECRET")
  existing_token <- Sys.getenv("TIKTOK_COMM_TOKEN")

  if (!force && (existing_key != "" || existing_secret != "" || existing_token != "")) {
    overwrite <- usethis::ui_yeah(
      "Existing TikTok Commercial API credentials found. Overwrite?",
      no = "Keeping existing credentials"
    )
    if (!overwrite) {
      return(invisible(FALSE))
    }
  }

  # Prompt for client key and secret
  if (verbose) usethis::ui_info("Please enter your TikTok Commercial API credentials.")
  client_key <- readline(usethis::ui_field("Client Key: "))
  client_secret <- readline(usethis::ui_field("Client Secret: "))

  # Authenticate with the API
  url <- "https://open.tiktokapis.com/v2/oauth/token/"
  body <- list(
    client_key = client_key,
    client_secret = client_secret,
    grant_type = "client_credentials"
  )

  response <- tryCatch(
    httr::POST(
      url,
      httr::add_headers("Content-Type" = "application/x-www-form-urlencoded"),
      body = body,
      encode = "form"
    ),
    error = function(e) {
      if (verbose) usethis::ui_oops("Failed to connect to TikTok API: {e$message}")
      return(NULL)
    }
  )

  if (is.null(response) || httr::status_code(response) != 200) {
    if (verbose) usethis::ui_oops("Authentication failed. Please check your credentials and try again.")
    return(invisible(FALSE))
  }

  content <- jsonlite::fromJSON(httr::content(response, "text", encoding = "UTF-8"))

  if ("error" %in% names(content)) {
    if (verbose) usethis::ui_oops("Authentication error: {content$error_description}")
    return(invisible(FALSE))
  }

  token <- list(
    access_token = content$access_token,
    expires_in = content$expires_in,
    token_type = content$token_type,
    expires_at = as.character(lubridate::now() + lubridate::seconds(content$expires_in))
  )

  # Store credentials in .Renviron
  set_renv(
    TIKTOK_COMM_CLIENT_KEY = client_key,
    TIKTOK_COMM_CLIENT_SECRET = client_secret,
    TIKTOK_COMM_TOKEN = jsonlite::toJSON(token, auto_unbox = TRUE)
  )

  if (verbose) {
    usethis::ui_done("TikTok Commercial API credentials have been stored in your .Renviron file.")
    usethis::ui_todo("Restart R for changes to take effect.")
  }

  invisible(TRUE)
}

#' Retrieve TikTok Commercial API Token
#'
#' This function retrieves the stored access token or authenticates if necessary.
#'
#' @param verbose Logical. If TRUE, provides detailed output. Default is FALSE.
#'
#' @return A list containing the client access token, expiration time, and token type.
#' @export
#'
#' @examples
#' \dontrun{
#' token <- tiktokcomm_get_token()
#' }
tiktokcomm_get_token <- function(verbose = FALSE) {
  stored_token <- Sys.getenv("TIKTOK_COMM_TOKEN")

  if (stored_token == "") {
    if (verbose) usethis::ui_oops("No stored token found. Please run tiktokcomm_auth() to set up your credentials.")
    return(NULL)
  }

  # Parse the token string
  token_parts <- strsplit(stored_token, ",")[[1]]
  token <- list(
    access_token = sub(".*:(.*)", "\\1", token_parts[1]),
    expires_in = as.numeric(sub(".*:(.*)", "\\1", token_parts[2])),
    token_type = sub(".*:(.*)", "\\1", token_parts[3])
  )


  # Handle the expires_at field separately
  token$expires_at <- stringr::str_split(token_parts[4], "expires_at:") %>% unlist() %>% .[2] %>% stringr::str_remove("\\}") %>% lubridate::as_datetime()


  if (lubridate::as_datetime(token$expires_at) <= lubridate::now()) {
    if (verbose) usethis::ui_info("Stored token has expired. Refreshing...")
    tiktokcomm_auth(force = TRUE, verbose = verbose)
    token <- jsonlite::fromJSON(Sys.getenv("TIKTOK_COMM_TOKEN"))
  }

  return(token)
}
