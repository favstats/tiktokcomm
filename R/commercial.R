#' Query TikTok Commercial Content
#'
#' This function queries the TikTok Commercial API for commercial content based on specified criteria.
#'
#' @param start_date Character. Start date for the query in "YYYY-MM-DD" format. Must be after 2022-10-01.
#' @param end_date Character. End date for the query in "YYYY-MM-DD" format.
#' @param creator_country_code Character. The country code of the content creator. Default is "ALL".
#' @param creator_usernames Character vector. The usernames of specific creators to query.
#' @param fields Character vector. The fields to retrieve. Default includes all available fields.
#' @param max_count Numeric. Maximum number of results to return per page (default 10, max 50).
#' @param max_pages Numeric. Maximum number of pages to retrieve. Default is Inf (all pages).
#' @param verbose Logical. If TRUE, provides detailed output. Default is FALSE.
#'
#' @return A tidy dataframe containing the queried commercial content data.
#' @export
#'
#' @importFrom httr POST add_headers content
#' @importFrom jsonlite fromJSON toJSON
#' @importFrom dplyr bind_rows mutate
#' @importFrom tidyr unnest_wider unnest_longer
#' @importFrom purrr map_dfr
#' @importFrom lubridate ymd as_datetime
#' @importFrom tibble tibble
#' @importFrom usethis ui_done ui_oops ui_info
#'
#' @examples
#' \dontrun{
#' commercial_content <- tiktokcomm_query_commercial_content(
#'   start_date = "2023-01-02",
#'   end_date = "2023-01-09",
#'   creator_country_code = "FR",
#'   max_count = 20,
#'   verbose = TRUE
#' )
#' }
tiktokcomm_query_commercial_content <- function(start_date,
                                                end_date,
                                                creator_country_code = "ALL",
                                                creator_usernames = NULL,
                                                fields = c("id", "create_timestamp", "create_date", "label", "brand_names", "creator", "videos"),
                                                max_count = 10,
                                                max_pages = Inf,
                                                verbose = FALSE) {

  # Validate dates
  start_date <- as.Date(start_date)
  end_date <- as.Date(end_date)
  if (start_date < as.Date("2022-10-01")) {
    stop("start_date must be after 2022-10-01")
  }
  if (end_date < start_date) {
    stop("end_date must be after start_date")
  }

  token <- tiktokcomm_get_token(verbose = verbose)
  if (is.null(token)) {
    stop("Authentication required. Please run tiktokcomm_auth() first.")
  }

  url <- "https://open.tiktokapis.com/v2/research/adlib/commercial_content/query/"

  query_params <- list(fields = paste(fields, collapse = ","))

  filters <- list(
    content_published_date_range = list(
      min = format(start_date, "%Y%m%d"),
      max = format(end_date, "%Y%m%d")
    ),
    creator_country_code = creator_country_code
  )

  if (!is.null(creator_usernames)) {
    filters$creator_usernames <- as.list(creator_usernames)
  }

  body <- list(
    filters = filters,
    max_count = max_count
  )

  all_content <- tibble::tibble()
  page <- 1
  search_id <- NULL

  repeat {
    if (verbose) usethis::ui_info("Retrieving page {page}...")

    if (!is.null(search_id)) {
      body$search_id <- search_id
    }

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

    if (verbose) usethis::ui_done("Retrieved {length(content$data$commercial_contents)} items on page {page}.")

    if (length(content$data$commercial_contents) == 0) {
      if (verbose) usethis::ui_info("No more results.")
      break
    }

    page_content <- purrr::map_dfr(content$data$commercial_contents, function(item) {
      tibble::tibble(
        id = item$id,
        create_timestamp = lubridate::as_datetime(item$create_timestamp),
        create_date = lubridate::ymd(item$create_date),
        label = item$label,
        brand_names = list(item$brand_names),
        creator_username = item$creator$username,
        videos = list(item$videos)
      )
    })

    all_content <- dplyr::bind_rows(all_content, page_content)

    if (!content$data$has_more || page >= max_pages) {
      if (verbose) usethis::ui_done("All pages retrieved or max_pages reached.")
      break
    }

    search_id <- content$data$search_id
    page <- page + 1
  }

  # Unnest the brand_names and videos columns
  all_content <- all_content %>%
    tidyr::unnest_longer(brand_names) %>%
    tidyr::unnest_wider(videos, names_sep = "_")

  if (verbose) usethis::ui_done("Total commercial content items retrieved: {nrow(all_content)}")

  return(all_content)
}
