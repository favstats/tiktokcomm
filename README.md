
<!-- README.md is generated from README.Rmd. Please edit that file -->

# tiktokcomm

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![CRAN
status](https://www.r-pkg.org/badges/version/tiktokcomm)](https://CRAN.R-project.org/package=tiktokcomm)
<!-- badges: end -->

The goal of tiktokcomm is to provide an R interface to the TikTok
Commercial API, allowing users to query ads, advertisers, and commercial
content data.

## Installation

You can install the development version of tiktokcomm from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("favstats/tiktokcomm")
```

## Load in the library

``` r
library(tiktokcomm)
```

## Authentication

Before using any of the functions, you need to authenticate with the
TikTok Commercial API. Use the tiktokcomm_auth() function to set up your
credentials:

``` r

tiktokcomm_auth()
```

This function will prompt you to enter your TikTok Commercial API client
key and secret. It will store these securely and use them to obtain
access tokens as needed.

# Functions

## Query Ads

``` r
tiktokcomm_query_ads(
  start_date = "2024-01-01",
  end_date = "2024-03-31",
  country_code = "DE",
  search_term = "example",
  max_count = 5,
  max_pages = 1,
  verbose = F
)
#> # A tibble: 5 × 10
#>        id first_shown_date last_shown_date status image_urls videos     reach   
#>     <dbl> <date>           <date>          <chr>  <list>     <list>     <chr>   
#> 1 1.79e15 2024-01-08       2024-01-09      active <NULL>     <list [1]> 10K-100K
#> 2 1.79e15 2024-01-07       2024-01-08      active <NULL>     <list [1]> 10K-100K
#> 3 1.79e15 2024-01-12       2024-01-14      active <NULL>     <list [1]> 10K-100K
#> 4 1.79e15 2024-02-02       2024-02-03      active <NULL>     <list [1]> 1K-10K  
#> 5 1.79e15 2024-02-11       2024-02-13      active <NULL>     <list [1]> 1K-10K  
#> # ℹ 3 more variables: advertiser_business_id <dbl>,
#> #   advertiser_business_name <chr>, advertiser_paid_for_by <chr>
```

This function queries the TikTok Commercial API for ads based on
specified criteria.

You can also add details to the ads:

``` r
tiktokcomm_query_ads(
  start_date = "2024-01-01",
  end_date = "2024-03-31",
  country_code = "DE",
  search_term = "example",
  max_count = 5,
  max_pages = 1, 
  include_details = T,
  verbose = F
)
#> # A tibble: 5 × 24
#>        id first_shown_date last_shown_date status image_urls videos     reach   
#>     <dbl> <date>           <date>          <chr>  <list>     <list>     <chr>   
#> 1 1.79e15 2024-01-08       2024-01-09      active <NULL>     <list [1]> 10K-100K
#> 2 1.79e15 2024-01-07       2024-01-08      active <NULL>     <list [1]> 10K-100K
#> 3 1.79e15 2024-01-12       2024-01-14      active <NULL>     <list [1]> 10K-100K
#> 4 1.79e15 2024-02-02       2024-02-03      active <NULL>     <list [1]> 1K-10K  
#> 5 1.79e15 2024-02-11       2024-02-13      active <NULL>     <list [1]> 1K-10K  
#> # ℹ 17 more variables: advertiser_business_id <dbl>,
#> #   advertiser_business_name <chr>, advertiser_paid_for_by <chr>,
#> #   status_statement <chr>, reach_unique_users_seen <chr>,
#> #   reach_unique_users_seen_by_country <list>, business_id <dbl>,
#> #   business_name <chr>, paid_for_by <chr>, targeting_info_age <list>,
#> #   targeting_info_audience_targeting <chr>, targeting_info_country <list>,
#> #   targeting_info_creator_interactions <chr>, targeting_info_gender <list>, …
```

## Query Advertisers

``` r
tiktokcomm_query_advertisers(
  search_term = "awesome",
  max_count = 25,
  verbose = F
)
#> # A tibble: 25 × 3
#>    business_id business_name     country_code
#>          <dbl> <chr>             <chr>       
#>  1     7.26e18 Awesome Cosmetics PL          
#>  2     7.41e18 AWESOME           TH          
#>  3     7.41e18 SJAJSF            US          
#>  4     7.17e18 Adidog            IE          
#>  5     7.41e18 OYIB              ID          
#>  6     7.41e18 OYIB              ID          
#>  7     7.41e18 OYIB              ID          
#>  8     7.41e18 OYIB              ID          
#>  9     7.41e18 OYIB              ID          
#> 10     7.41e18 OYIB              ID          
#> # ℹ 15 more rows
```

This function queries the TikTok Commercial API for advertisers based on
a search term.

## Get Ad Details

``` r
tiktokcomm_get_ad_details(
  ad_id = 1812268576617521,
  verbose = F
)
#> # A tibble: 1 × 20
#>        id first_shown_date last_shown_date status status_statement image_urls
#>     <dbl> <date>           <date>          <chr>  <chr>            <list>    
#> 1 1.81e15 2024-10-09       2024-10-09      active N/A              <list [1]>
#> # ℹ 14 more variables: videos <list>, reach_unique_users_seen <chr>,
#> #   reach_unique_users_seen_by_country <list>, business_id <dbl>,
#> #   business_name <chr>, paid_for_by <chr>, targeting_info_interest <chr>,
#> #   targeting_info_number_of_users_targeted <chr>,
#> #   targeting_info_video_interactions <chr>, targeting_info_age <list>,
#> #   targeting_info_audience_targeting <chr>, targeting_info_country <list>,
#> #   targeting_info_creator_interactions <chr>, targeting_info_gender <list>
```

This function retrieves detailed information about a specific TikTok ad.

## Get Ad Report (this does not seem to work right now)

``` r
tiktokcomm_get_ad_report(
  start_date = "2023-01-02",
  end_date = "2023-01-09",
  country_code = "ALL",
  advertiser_ids = c(7057157514558702338, 6876483895102014209),
  verbose = F
)
#> # A tibble: 0 × 0
```

This function retrieves a report on ad publishing from the TikTok
Commercial API.

## Query Commercial Content

``` r
tiktokcomm_query_commercial_content(
  start_date = "2023-01-02",
  end_date = "2023-01-09",
  creator_country_code = "FR",
  max_count = 50,
  max_pages = 5,
  verbose = F
)
#> # A tibble: 250 × 7
#>    id         create_timestamp    create_date label brand_names creator_username
#>    <chr>      <dttm>              <date>      <chr> <chr>       <chr>           
#>  1 v09044g40… 2023-01-07 18:02:46 2023-01-07  Paid… ""          kodhproducer    
#>  2 v09044g40… 2023-01-03 08:40:09 2023-01-03  Paid… ""          celia.dahan     
#>  3 v09044g40… 2023-01-02 15:06:04 2023-01-02  Paid… ""          beckr4real      
#>  4 v09044g40… 2023-01-02 10:03:25 2023-01-02  Paid… ""          marketdamp      
#>  5 v09044g40… 2023-01-02 17:11:17 2023-01-02  Paid… ""          sarabel__       
#>  6 v09044g40… 2023-01-03 18:21:11 2023-01-03  Paid… ""          jayf2.0         
#>  7 v09044g40… 2023-01-03 14:58:46 2023-01-03  Paid… ""          louisergtt      
#>  8 v09044g40… 2023-01-09 18:56:06 2023-01-09  Paid… ""          thibaultodiot   
#>  9 v09044g40… 2023-01-09 16:12:24 2023-01-09  Paid… ""          vvvanel         
#> 10 v09044g40… 2023-01-09 18:06:37 2023-01-09  Paid… ""          micke_geek      
#> # ℹ 240 more rows
#> # ℹ 1 more variable: videos_1 <list>
```

This function queries the TikTok Commercial API for commercial content
based on specified criteria.

# Notes

All date inputs should be in “YYYY-MM-DD” format.

The verbose parameter in each function, when set to TRUE, provides
detailed output about the API requests and responses.

Most functions support pagination. Use max_count to set the number of
results per page and max_pages to limit the total number of pages
retrieved.

# Contributing

Contributions to `tiktokcomm` are welcome. Please refer to the
contribution guidelines for more information.

# License

This project is licensed under the MIT License - see the LICENSE.md file
for details.
