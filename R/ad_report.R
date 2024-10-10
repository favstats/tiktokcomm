#' Get TikTok Ad Report
#'
#' This function retrieves a report on ad publishing from the TikTok Commercial API.
#'
#' @param start_date Character. Start date for the report in "YYYY-MM-DD" format. Must be after 2022-10-01.
#' @param end_date Character. End date for the report in "YYYY-MM-DD" format.
#' @param country_code Character. The country code to filter by. Default is "ALL".
#' @param advertiser_ids Character vector or single character value. The advertiser business ID(s) to filter by.
#' @param fields Character vector. The fields to retrieve. Default is "count_time_series_by_country".
#' @param verbose Logical. If TRUE, provides detailed output. Default is FALSE.
#'
#' @return A tidy dataframe containing the ad report data.
#' @export
#'
#' @importFrom httr POST add_headers content
#' @importFrom jsonlite fromJSON toJSON
#' @importFrom dplyr bind_rows mutate
#' @importFrom tidyr pivot_longer unnest
#' @importFrom purrr map_dfr
#' @importFrom lubridate ymd
#' @importFrom tibble tibble
#' @importFrom usethis ui_done ui_oops ui_info
#'
#' @examples
#' \dontrun{
#' ad_report <- tiktokcomm_get_ad_report(
#'   start_date = "2023-01-02",
#'   end_date = "2023-01-09",
#'   country_code = "DE",
#'   advertiser_ids = "7057157514558702338",
#'   verbose = TRUE
#' )
#' }
tiktokcomm_get_ad_report <- function(start_date,
                                     end_date,
                                     country_code = "ALL",
                                     advertiser_ids = NULL,
                                     fields = "count_time_series_by_country",
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

  # Ensure advertiser_ids is a list of strings
  if (!is.null(advertiser_ids)) {
    advertiser_ids <- as.list(as.character(advertiser_ids))
  }

  token <- tiktokcomm_get_token(verbose = verbose)
  if (is.null(token)) {
    stop("Authentication required. Please run tiktokcomm_auth() first.")
  }

  url <- "https://open.tiktokapis.com/v2/research/adlib/ad/report/"

  query_params <- list(fields = paste(fields, collapse = ","))

  filters <- list(
    ad_published_date_range = list(
      min = format(start_date, "%Y%m%d"),
      max = format(end_date, "%Y%m%d")
    ),
    country_code = country_code
  )

  if (!is.null(advertiser_ids)) {
    filters$advertiser_business_ids <- advertiser_ids
  }

  body <- list(filters = filters)

  if (verbose) usethis::ui_info("Retrieving ad report...")

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

  if (verbose) usethis::ui_done("Retrieved ad report successfully.")

  # Process the response into a tidy dataframe
  report_data <- purrr::map_dfr(names(content$data$count_time_series_by_country), function(country) {
    tibble::tibble(
      country = country,
      data = list(content$data$count_time_series_by_country[[country]])
    )
  })

  if(length(names(report_data)!=0)){
    report_data <- report_data %>%
      tidyr::unnest(data) %>%
      dplyr::mutate(date = lubridate::ymd(date))

    if (verbose) usethis::ui_done("Ad report processed into a tidy dataframe.")

  } else {
    if (verbose) usethis::ui_oops("Ad report is empty.")
    report_data <- tibble()
  }




  return(report_data)
}
