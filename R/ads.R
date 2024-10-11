#' Query TikTok Ads with Automatic Pagination
#'
#' This function queries the TikTok Commercial API for ads based on specified criteria,
#' automatically handling pagination to retrieve all available results.
#'
#' @param fields Character vector of fields to retrieve. Default includes all available fields.
#' @param start_date Start date for ad publication range. Format: "YYYY-MM-DD". Must be after 2022-10-01.
#' @param end_date End date for ad publication range. Format: "YYYY-MM-DD".
#' @param country_code The country where the ads were targeted. Default is NULL (all countries).
#' @param advertiser_ids Vector of advertiser business IDs.
#' @param min_users Minimum number of users who've seen the ad. Use suffixes K, M, or B (e.g., "10K").
#' @param max_users Maximum number of users who've seen the ad. Use suffixes K, M, or B (e.g., "1M").
#' @param search_term Optional search term (max 50 characters).
#' @param search_type Type of search ("exact_phrase" or "fuzzy_phrase"). Default is "exact_phrase".
#' @param max_count Maximum number of results to return per page (default 10, max 50).
#' @param max_pages Maximum number of pages to retrieve. Default is Inf (all pages).
#' @param include_details Logical. If TRUE, fetches detailed information for each ad. Default is FALSE.
#' @param verbose Logical. If TRUE, provides detailed output. Default is FALSE.
#' @param safe Logical. If TRUE, provides detailed output. Default is FALSE.

#' @return A tibble containing all retrieved ads.
#' @export
#'
#' @importFrom httr POST add_headers content
#' @importFrom jsonlite fromJSON toJSON
#' @importFrom dplyr bind_rows
#' @importFrom purrr map_df
#' @importFrom tibble tibble
#' @importFrom usethis ui_done ui_oops ui_info
#' @importFrom lubridate ymd
#'
#' @examples
#' \dontrun{
#' results <- tiktokcomm_query_ads(
#'   start_date = "2023-01-01",
#'   end_date = "2023-03-31",
#'   country_code = "DE",
#'   search_term = "mobile games",
#'   max_count = 20,
#'   max_pages = 5
#' )
#' }
tiktokcomm_query_ads <- function(fields = c("ad.id", "ad.first_shown_date", "ad.last_shown_date", "ad.status", "ad.status_statement",
                                            "ad.videos", "ad.image_urls", "ad.reach", "advertiser.business_id", "advertiser.business_name", "advertiser.paid_for_by"),
                                 start_date = NULL,
                                 end_date = NULL,
                                 country_code = NULL,
                                 advertiser_ids = NULL,
                                 min_users = NULL,
                                 max_users = NULL,
                                 search_term = NULL,
                                 search_type = "exact_phrase",
                                 max_count = 10,
                                 max_pages = Inf,
                                 include_details = FALSE,
                                 verbose = FALSE,
                                 safe = F) {

  token <- tiktokcomm_get_token(verbose = verbose)
  if (is.null(token)) {
    stop("Authentication required. Please run tiktokcomm_auth() first.")
  }

  # Parse and validate dates
  if (!is.null(start_date)) {
    start_date <- format(lubridate::ymd(start_date), "%Y%m%d")
    if (start_date < "20221001") stop("start_date must be after 2022-10-01")
  }
  if (!is.null(end_date)) {
    end_date <- format(lubridate::ymd(end_date), "%Y%m%d")
  }

  # Construct filters
  filters <- list()
  if (!is.null(start_date) || !is.null(end_date)) {
    filters$ad_published_date_range <- list(
      min = start_date,
      max = end_date
    )
  }
  if (!is.null(country_code)) filters$country_code <- country_code
  if (!is.null(advertiser_ids)) filters$advertiser_business_ids <- advertiser_ids
  if (!is.null(min_users) || !is.null(max_users)) {
    filters$unique_users_seen_size_range <- list(
      min = min_users %||% "0K",  # Default to "0K" if min_users is not provided
      max = max_users %||% "1B"   # Default to "1B" if max_users is not provided
    )
  }

  url <- "https://open.tiktokapis.com/v2/research/adlib/ad/query/"
  all_ads <- tibble::tibble()
  page <- 1
  search_id <- NULL

  repeat {
    if (verbose) usethis::ui_info("Retrieving page {page}...")

    query_params <- list(fields = paste(fields, collapse = ","))

    body <- list(
      filters = filters,
      search_term = search_term,
      search_type = search_type,
      max_count = max_count
    )
    if (!is.null(search_id)) body$search_id <- search_id

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
      if(!safe){
      stop(glue::glue("Status code: {httr::status_code(response)}"))
      } else {
        break
      }

    }

    content <- httr::content(response, "parsed", encoding = "UTF-8")

    if (verbose) usethis::ui_done("Retrieved {length(content$data$ads)} ads on page {page}.")

    if (is.null(content$data$ads) || length(content$data$ads) == 0) {
      if (verbose) usethis::ui_info("No more results.")
      break
    }

    page_ads <- purrr::map_df(content$data$ads, function(ad) {
      ad_data <- tibble::tibble(
        id = ad$ad$id,
        first_shown_date = lubridate::ymd(ad$ad$first_shown_date),
        last_shown_date = lubridate::ymd(ad$ad$last_shown_date),
        status = ad$ad$status,
        image_urls = list(ad$ad$image_urls),
        videos = list(ad$ad$videos),
        reach = ad$ad$reach$unique_users_seen,
        advertiser_business_id = ad$advertiser$business_id,
        advertiser_business_name = ad$advertiser$business_name,
        advertiser_paid_for_by = ad$advertiser$paid_for_by
      )

      if (include_details) {
        # if (verbose) usethis::ui_info("Fetching details for ad {ad$ad$id}")
        ad_details <- tiktokcomm_get_ad_details(ad$ad$id, verbose = FALSE)

        # Get column names that are already in ad_data
        names_already_present <- names(ad_data %>% dplyr::select(-"id"))

        # Filter to keep only those names that exist in ad_details
        names_to_remove <- intersect(names_already_present, names(ad_details))

        # Perform the join, selecting columns excluding those that are already present in ad_data
        ad_data <- dplyr::left_join(
          ad_data,
          ad_details %>% dplyr::select(-all_of(names_to_remove)),
          by = "id"
        )
      }

      return(ad_data)

    })

    all_ads <- dplyr::bind_rows(all_ads, page_ads)

    if (!content$data$has_more || page >= max_pages) {
      if (verbose) usethis::ui_done("All pages retrieved or max_pages reached.")
      break
    }

    search_id <- content$data$search_id
    page <- page + 1
  }

  if (verbose) usethis::ui_done("Total ads retrieved: {nrow(all_ads)}")

  return(all_ads)
}
