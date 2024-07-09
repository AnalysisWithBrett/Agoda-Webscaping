# Booking.com webscraping
library(RSelenium)
library(tidyverse)
library(stringr)

# setting working directory
setwd('C://Users//hoybr//Documents//data_projects//indonesia_project//booking_com')

# Getting the versions of chromedriver
binman::list_versions("chromedriver")


# Creating the chrome driver
rs_driver_chrome <- rsDriver(
  browser = "chrome",
  chromever = "126.0.6478.126"
)

Sys.sleep(6)

# Access the client object - helps control selenium
remDr <- rs_driver_chrome$client

sanur_url <- "https://www.booking.com/searchresults.html?ss=Sanur%2C+Bali%2C+Indonesia&ssne=Denpasar&ssne_untouched=Denpasar&label=gen173nr-1FCAEoggI46AdIM1gEaFCIAQGYATG4ARfIAQzYAQHoAQH4AQKIAgGoAgO4AtH0qLQGwAIB0gIkMGRkMmIzMzItODFlMC00NGQ1LWI0YmMtMTA0ZGNmZjJhNTdj2AIF4AIB&aid=304142&lang=en-us&sb=1&src_elem=sb&src=index&dest_id=325646&dest_type=city&ac_position=0&ac_click_type=b&ac_langcode=en&ac_suggestion_list_length=5&search_selected=true&search_pageview_id=c7f92fe8b52b008c&ac_meta=GhBjN2Y5MmZlOGI1MmIwMDhjIAAoATICZW46BXNhbnVyQABKAFAA&checkin=2024-09-19&checkout=2024-09-20&group_adults=1&no_rooms=1&group_children=0"


# Launching the website
remDr$navigate(sanur_url)

Sys.sleep(6)

# Closing the cookies
remDr$findElement(using = "xpath", "//button[@id='onetrust-reject-all-handler']")$clickElement()

Sys.sleep(2)

# Closing the cookies
# remDr$findElement(using = "xpath", "//button[@id='onetrust-reject-all-handler']")$clickElement()


# Scrolling script
scrolling_script <- scrolling_script <- "
    (function() {
        let lastScrollHeight = 0;
        let scrollCount = 0;
        const maxScrolls = 50;  // Maximum number of scroll attempts
        const scrollStep = 1600; // Amount to scroll per step
        const scrollInterval = 1400; // Time between scroll steps in milliseconds
        let intervalId;

        function scrollDown() {
            const scrollHeight = document.body.scrollHeight;
            const currentScroll = window.scrollY + window.innerHeight;

            if (currentScroll < scrollHeight) {
                window.scrollBy(0, scrollStep);
                lastScrollHeight = scrollHeight;
                scrollCount = 0;  // Reset scroll count if new content is loaded
            } else {
                scrollCount++;
            }
            
            if (scrollCount >= 3 || maxScrolls <= 0) {  // Stop if no new content after 3 scrolls or maxScrolls is reached
                clearInterval(intervalId);
            }

            maxScrolls--;
        }

        intervalId = setInterval(scrollDown, scrollInterval);  // Adjust interval as needed
    })();
";


# Scrolling the webpage
remDr$executeScript(scrolling_script)

Sys.sleep(30)

for (i in 1:10) {  # Set a higher limit to ensure all reviews are loaded
  # Check if the load more button is present
  load_more_button <- tryCatch({
    remDr$findElement(using = "xpath", "//button[@class='bf33709ee1 a190bb5f27 b9d0a689f2 bb5314095f b81c794d25 da4da790cd']")
  }, error = function(e) {
    NULL
  })
  
  # If the button is not found, exit the loop
  if (is.null(load_more_button)) {
    message("No more 'Load More Ratings' button found. Exiting loop.")
    break
  }
  
  # Scroll to the element and click it
  y_position <- load_more_button$getElementLocation()$y - 100 # determine y position of element - 100
  remDr$executeScript(sprintf("window.scrollTo(0, %f)", y_position)) # scroll to the element
  load_more_button$clickElement() # click the element
  Sys.sleep(6) # pause code for one and half seconds
}



# Locate all property cards
property_cards <- remDr$findElements(using = "xpath", "//div[contains(@class, 'fa298e29e2') or contains(@class, 'b74446e476') or contains(@class, 'e40c0c68b1') or contains(@class, 'ea1d0cfcb7') or contains(@class, 'd8991ab7ae') or contains(@class, 'e8b7755ec7') or contains(@class, 'ad0e783e41')]")

# Extract URLs from the property cards
# Assuming the URL is within an <a> tag inside the property card
property_urls <- map(property_cards, function(card) {
  # Find <a> tags within the card
  links <- card$findChildElements(using = "xpath", ".//a")
  
  # Extract 'href' attribute from each <a> tag
  urls <- sapply(links, function(link) link$getElementAttribute("href") %>% unlist())
  
  # Return the first URL (if multiple links are present, you might need to adjust)
  if (length(urls) > 0) {
    return(urls[1])
  } else {
    return(NA)  # Return NA if no URL is found
  }
})

# Remove any NA values from the list
property_urls <- property_urls[!is.na(property_urls)]

# Checking the number of urls
length(property_urls)

# Initialize an empty data frame to store all booking data
booking_data <- data.frame()


# Creating the main loop
for (url in property_urls) {
  tryCatch({
    # Navigate to the property's page
    remDr$navigate(url)
    Sys.sleep(4)  # Wait for the page to load completely
    
    # Find property name
    property_name <- tryCatch({
      remDr$findElement(using = "xpath", "//h2[starts-with(@class, 'aceeb7ecbc')]")$getElementText() %>% unlist()
    }, error = function(e){
      "Unknown Property"
    })
    
    # Address
    address <- tryCatch({
      remDr$findElement(using = "xpath", "//span[contains(@class, 'hp_address_subtitle') and contains(@class, 'js-hp_address_subtitle') and contains(@class, 'jq_tooltip')]")$getElementText() %>% unlist()
    }, error = function(e){
      "Unknown Address"
    })
    
    # Find reviews (handle case where no reviews are found)
    reviews_elements <- remDr$findElements(using = "xpath", "//span[contains(@class, 'f13857cc8c') and contains(@class, 'a5cc9f664c') and contains(@class, 'c4b07b6aa8')]")
    if (length(reviews_elements) > 0) {
      reviews <- sapply(reviews_elements, function(elem) elem$getElementText() %>% unlist())
    } else {
      reviews <- "No reviews"
    }
    
    # Find score rating (handle case where no score rating is found)
    score_rating_elements <- remDr$findElements(using = "xpath", "//*[@id='js--hp-gallery-scorecard']/a/div/div/div/div[1]")
    if (length(score_rating_elements) > 0) {
      score_rating <- sapply(score_rating_elements, function(elem) elem$getElementText()[[1]] %>% unlist())
    } else {
      score_rating <- "0"
    }
    
    # Find star rating (handle case where no star rating is found)
    star_elements <- remDr$findElements(using = "xpath", "//span[contains(@class, 'eed6ad6ae5') and contains(@class, 'd3887aa36c') and contains(@class, 'f78d1a26ba')]")
    if (length(star_elements) > 0) {
      star_ratings <- sapply(star_elements, function(elem) elem$getElementText()) %>% unlist()
      number_stars <- length(star_ratings)
    } else {
      number_stars <- 0
    }
    
    # Find room types
    room_elements <- remDr$findElements(using = "xpath", "//span[contains(@class, 'hprt-roomtype-icon-link')]")
    room_types <- sapply(room_elements, function(elem) elem$getElementText() %>% unlist())
    
    # Find <td> elements with rowspan
    elements <- remDr$findElements(using = "xpath", "//td[contains(@class, 'hprt-table-cell') and contains(@class, 'hprt-table-cell-roomtype') and contains(@class, 'droom_seperator') and @rowspan]")
    rowspan_strings <- sapply(elements, function(elem) elem$getElementAttribute("rowspan") %>% unlist())
    rowspan_values <- as.numeric(rowspan_strings)
    
    # Initialize a vector for room types
    room <- c()
    for (i in seq_along(rowspan_values)) {
      room <- c(room, rep(room_types[i], rowspan_values[i]))
    }
    
    # Find prices
    price_elements <- remDr$findElements(using = "xpath", "//span[contains(@class, 'prco-valign-middle-helper')]")
    prices <- sapply(price_elements, function(elem) elem$getElementText() %>% unlist())
    
    # Ensure room and price lengths match
    if (length(room) == length(prices)) {
      # Create a dataframe for the current property
      booking_property_data <- data.frame(
        Property_Name = rep(property_name, length(prices)),
        Address = rep(address, length(prices)),
        Score_Rating = rep(score_rating, length(prices)),  # Ensure score rating is included
        Reviews = rep(reviews, length(prices)),  # Ensure reviews are included
        Star_Rating = rep(number_stars, length(prices)),  # Ensure star rating is included
        Price = prices,
        RoomType = room,
        stringsAsFactors = FALSE
      )
      
      # Bind to main dataframe
      booking_data <- bind_rows(booking_data, booking_property_data)
    } else {
      warning("Mismatch between room types and prices for URL: ", url)
    }
    
    # Print the property name for progress
    print(property_name)
    
    # Pause before moving to the next property
    Sys.sleep(4)
  }, error = function(e) {
    message("Error processing URL: ", url)
    message("Error details: ", e$message)
  })
}


# Cleaning the data
# Function to extract the first numeric value from the text
extract_first_number_gsub <- function(text) {
  # Remove all characters except for digits and decimal points
  cleaned_text <- gsub(".*?(\\d+\\.\\d+|\\d+).*", "\\1", text)
  # Convert the result to numeric, if it's empty or not a valid number, return NA
  if (cleaned_text == "" || is.na(as.numeric(cleaned_text))) {
    return(NA)
  } else {
    return(as.numeric(cleaned_text))
  }
}

# Apply the function to the dataframe column
booking_data$scoreRating <- sapply(booking_data$Score_Rating, extract_first_number_gsub)

# Removing the currency symbol
booking_data$price_cleaned <- as.numeric(gsub("£", "", booking_data$Price))


# Function to extract the first numeric value from a text
extract_first_number <- function(text) {
  # Use gsub to remove non-numeric characters and keep the first number found
  numeric_value <- gsub(".*?(\\d+).*", "\\1", text)
  # If numeric_value is empty, return 0, otherwise convert to numeric
  if (numeric_value == "" || is.na(as.numeric(numeric_value))) {
    return(0)
  } else {
    return(as.numeric(numeric_value))
  }
}

# Closing the server
remDr$close()
rs_driver_chrome$server$stop()


# Apply the function to the dataframe column
booking_data$num_reviews <- sapply(booking_data$Reviews, extract_first_number)


# Converting to dollar currency
booking_cleaned <- booking_data %>% 
  dplyr::select(-Price, -Reviews, -Score_Rating) %>% 
  mutate(price_dollar = price_cleaned * 1.28)


# Define a regular expression to match the postcode (5 digits)
postcode_pattern <- "\\b\\d{5}\\b"

# Importing the postcode data
postcode <- read.csv("C:\\Users\\hoybr\\Documents\\data_projects\\indonesia_project\\booking_com\\coordinates.csv")


# Extract the postcode and filtering it within 15km of Sanur
booking_filtered <- booking_cleaned %>%
  mutate(Postcode = str_extract(Address, postcode_pattern)) %>% 
  filter(Postcode %in% c(postcode$postcode)) %>% 
  distinct()

# Importing the postcode data
booking_outdate <- read.csv("C:\\Users\\hoybr\\Documents\\data_projects\\indonesia_project\\booking_com\\booking_filtered.csv")

# Combining the data
booking_done <- rbind(booking_filtered, booking_outdate) %>% 
  distinct()


# Exporting the data
write.csv(booking_done, file = "booking_filtered.csv", row.names = FALSE)
