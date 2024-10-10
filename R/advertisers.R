#' Query TikTok Advertisers
#'
#' This function queries the TikTok Commercial API for advertisers based on specified criteria.
#'
#' @param fields Character vector of fields to retrieve.
#'   Default is c("business_id", "business_name", "country_code").
#' @param search_term Required search term (max 50 characters).
#' @param max_count Maximum number of results to return (default 10, max 50).
#' @param verbose Logical. If TRUE, provides detailed output. Default is FALSE.
#'
#' @return A tibble containing all retrieved advertisers.
#' @export
#'
#' @importFrom httr POST add_headers content
#' @importFrom jsonlite fromJSON toJSON
#' @importFrom dplyr bind_rows
#' @importFrom purrr map_df
#' @importFrom tibble tibble
#' @importFrom usethis ui_done ui_oops ui_info
#'
#' @examples
#' \dontrun{
#' results <- tiktokcomm_query_advertisers(
#'   fields = c("business_id", "business_name", "country_code"),
#'   search_term = "awesome",
#'   max_count = 25,
#'   verbose = TRUE
#' )
#' }
tiktokcomm_query_advertisers <- function(fields = c("business_id", "business_name", "country_code"),
                                         search_term,
                                         max_count = 10,
                                         verbose = FALSE) {

  if (is.null(search_term) || nchar(search_term) > 50) {
    stop("search_term is required and must be 50 characters or less.")
  }

  token <- tiktokcomm_get_token(verbose = verbose)
  if (is.null(token)) {
    stop("Authentication required. Please run tiktokcomm_auth() first.")
  }

  url <- "https://open.tiktokapis.com/v2/research/adlib/advertiser/query/"

  query_params <- list(fields = paste(fields, collapse = ","))

  body <- list(
    search_term = search_term,
    max_count = max_count
  )

  if (verbose) usethis::ui_info("Querying advertisers...")

  response <- httr::POST(
    url,
    query = query_params,
    httr::add_headers(
      Authorization = paste("Bearer", token$access_token),
      "Content-Type" = "application/json"
    ),
    body = jsonlite::toJSON(body, auto_unbox = TRUE),
    encode = "json"
  )

  if (httr::status_code(response) != 200) {
    usethis::ui_oops("Query failed: {httr::content(response)$error$message}")
    stop(glue::glue("Status code: {httr::status_code(response)}"))
  }

  content <- httr::content(response, "parsed", encoding = "UTF-8")

  if (verbose) usethis::ui_done("Retrieved {length(content$data$advertisers)} advertisers.")

  advertisers <- purrr::map_df(content$data$advertisers, function(advertiser) {
    tibble::tibble(
      business_id = advertiser$business_id,
      business_name = advertiser$business_name,
      country_code = advertiser$country_code
    )
  })

  if (verbose) usethis::ui_done("Total advertisers retrieved: {nrow(advertisers)}")

  return(advertisers)
}
