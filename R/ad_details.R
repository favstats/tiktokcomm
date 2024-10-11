#' Get TikTok Ad Details
#'
#' This function retrieves detailed information about a specific TikTok ad using the Commercial API
#' and returns the results as a tidy dataframe.
#'
#' @param ad_id Numeric. The ID of the ad to retrieve details for.
#' @param fields Character vector of fields to retrieve.
#'   Default includes all available fields.
#' @param verbose Logical. If TRUE, provides detailed output. Default is FALSE.
#'
#' @return A tidy dataframe containing detailed information about the specified ad.
#' @export
#'
#' @importFrom httr POST add_headers content
#' @importFrom jsonlite fromJSON toJSON
#' @importFrom purrr map_dfr
#' @importFrom dplyr mutate across
#' @importFrom tidyr unnest_wider
#' @importFrom lubridate ymd
#' @importFrom tibble tibble
#' @importFrom usethis ui_done ui_oops ui_info
#'
#' @examples
#' \dontrun{
#' ad_details <- tiktokcomm_get_ad_details(
#'   ad_id = 104836593772645,
#'   verbose = TRUE
#' )
#' }
tiktokcomm_get_ad_details <- function(ad_id,
                                      fields = c("ad.id", "ad.first_shown_date", "ad.last_shown_date", "ad.status",
                                                 "ad.status_statement", "ad.videos", "ad.image_urls", "ad.reach",
                                                 "advertiser.business_id", "advertiser.business_name", "advertiser.paid_for_by",
                                                 "advertiser.follower_count", "advertiser.avatar_url", "advertiser.profile_url",
                                                 "ad_group.targeting_info", "ad.rejection_info"),
                                      verbose = FALSE) {

  if (is.null(ad_id) || !is.numeric(ad_id)) {
    stop("ad_id is required and must be numeric.")
  }

  token <- tiktokcomm_get_token(verbose = verbose)
  if (is.null(token)) {
    stop("Authentication required. Please run tiktokcomm_auth() first.")
  }

  url <- "https://open.tiktokapis.com/v2/research/adlib/ad/detail/"

  query_params <- list(fields = paste(fields, collapse = ","))

  body <- list(ad_id = ad_id)

  if (verbose) usethis::ui_info("Retrieving ad details for ad ID: {ad_id}")

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

  if (verbose) usethis::ui_done("Retrieved ad details successfully.")

  # Process the response into a tidy dataframe
  ad_details <- tibble::tibble(
    id = content$data$ad$id,
    first_shown_date = lubridate::ymd(content$data$ad$first_shown_date),
    last_shown_date = lubridate::ymd(content$data$ad$last_shown_date),
    status = content$data$ad$status,
    status_statement = content$data$ad$status_statement,
    image_urls = list(content$data$ad$image_urls),
    videos = list(content$data$ad$videos),
    reach = list(content$data$ad$reach),
    rejection_info = list(content$data$ad$rejection_info),
    business_id = content$data$advertiser$business_id,
    business_name = content$data$advertiser$business_name,
    paid_for_by = content$data$advertiser$paid_for_by,
    avatar_url = content$data$advertiser$tiktok_account$avatar_url,
    follower_count = content$data$advertiser$tiktok_account$follower_count,
    profile_url = content$data$advertiser$tiktok_account$profile_url,
    targeting_info = list(content$data$ad_group$targeting_info)
  )

  # Unnest the reach column
  # Unnest the targeting_info column
  ad_details <- ad_details %>%
    tidyr::unnest_wider(reach, names_sep = "_") %>%
    tidyr::unnest_wider(targeting_info, names_sep = "_")

  if (verbose) usethis::ui_done("Ad details processed into a tidy dataframe.")

  return(ad_details)
}
