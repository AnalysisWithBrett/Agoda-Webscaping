# Webscraping Parisian Properties in Christie's Rentals
library(RSelenium)
library(tidyverse)


# setting working directory
setwd('C://Users//hoybr//Documents//data_projects//Paris_Housing')

# Getting the versions of chromedriver
binman::list_versions("chromedriver")


# Creating the chrome driver
rs_driver_chrome <- rsDriver(
  browser = "chrome",
  chromever = "126.0.6478.126"
)


# Access the client object - helps control selenium
remDr <- rs_driver_chrome$client

# URL
paris_url <- "https://www.sothebysrealty.com/eng/rentals/paris-il-fra"

# Launching the website
remDr$navigate(paris_url)


# Scrolling script
scrolling_script <- scrolling_script <- "
    (function() {
        let lastScrollHeight = 0;
        let scrollCount = 0;
        const maxScrolls = 50;  // Maximum number of scroll attempts
        const scrollStep = 2000; // Amount to scroll per step
        const scrollInterval = 2000; // Time between scroll steps in milliseconds
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



############################
# Testing
###########################


# Locate all property cards
property_cards <- remDr$findElements(using = "xpath", "//div[contains(@class, 'Results-card__container') or contains(@class, 'Results-card__container--map')]")

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





# Collecting all property address
# Extract address elements using a CSS selector with the full class code
address_elements <- remDr$findElements(using = "css selector", ".header5.Results-card__body-address.u-features-title-small.u-color-sir-blue")

# Get the text from each element
addresses <- sapply(address_elements, function(el) el$getElementText())

filtered_addresses <- addresses[seq(2, length(addresses), by = 2)]






# Property name 
property_name <- tryCatch({
  remDr$findElement(using = "xpath", "//h2[contains(@class, 'ListingDescription__description-title') and contains(@class, 'h4') and contains(@class, 'u-color-dark-blue')]")$getElementText() %>% unlist()
}, error = function(e){
  "Unknown"
})

# Find address
address <- tryCatch({
  remDr$findElement(using = "xpath", "/html/body/div[1]/div/div/main/div[1]/section[1]/div[3]/div/div[1]/div[2]/h1/div[2]")$getElementText() %>% unlist()
}, error = function(e){
  "Unknown"
})

# Price
price <- tryCatch({
  price_element <- remDr$findElement(using = "xpath", "//div[contains(text(), 'Listing Price')]/following-sibling::div[contains(@class, 'FeatureList__content')]")
  price_element$getElementText()[[1]]
}, error = function(e){
  "Unknown"
})

# area in square feet
area <- tryCatch({
  area_element <- remDr$findElement(using = "xpath", "//div[contains(text(), 'total sqft')]/following-sibling::div[contains(@class, 'FeatureList__content')]")
  area_element$getElementText()[[1]]
}, error = function(e){
  "Unknown"
})

# Property type
property_type <- tryCatch({
  property_type_element <- remDr$findElement(using = "xpath", "//div[contains(text(), 'Property type')]/following-sibling::div[contains(@class, 'FeatureList__content')]")
  property_type_element$getElementText()[[1]]
}, error = function(e){
  "Unknown"
})

# Property Tax
property_tax <- tryCatch({
  property_tax_element <- remDr$findElement(using = "xpath", "//div[contains(text(), 'property taxes')]/following-sibling::div[contains(@class, 'FeatureList__content')]")
  property_tax_element$getElementText()[[1]]
}, error = function(e){
  "Unknown"
})


# Year built
year_built <- tryCatch({
  year_built_element <- remDr$findElement(using = "xpath", "//p[contains(text(), 'Year Built')]/following-sibling::p[contains(@class, 'h4-lap u-padding-top-8')]")
  year_built_element$getElementText()[[1]]
}, error = function(e){
  "Unknown"
})



# Number of bedrooms
bedroom <- tryCatch({
  bedroom_element <- remDr$findElement(using = "xpath", "//div[contains(text(), 'Bedrooms')]/following-sibling::div[contains(@class, 'FeatureList__content')]")
  bedroom_element$getElementText()[[1]]
}, error = function(e){
  "0"
})


# Full bathrooms
full_bath <- tryCatch({
  full_bath_element <- remDr$findElement(using = "xpath", "//div[contains(text(), 'Full Bathrooms')]/following-sibling::div[contains(@class, 'FeatureList__content')]")
  full_bath_element$getElementText()[[1]]
}, error = function(e) {
  "0"
})

# Partial Bathrooms
partial_bath <- tryCatch({
  partial_bath_element <- remDr$findElement(using = "xpath", "//div[contains(text(), 'Partial Bathrooms')]/following-sibling::div[contains(@class, 'FeatureList__content')]")
  partial_bath_element$getElementText()[[1]]
}, error = function(e) {
  "0"
})






# Indicating the data collected from this property
print(paste("Property Name:", property_name))
print(paste("Address:", address))
print(paste("Price:", price))
print(paste("Area:", area))
print(paste("Year Built:", year_built))
print(paste("Property Type:", property_type))
print(paste("Property Taxes:", property_tax))
print(paste("Bedroom:", bedroom))
print(paste("Full Bathroom:", full_bath))
print(paste("Partial Bathroom:", partial_bath))

# Creating data frame
paris_property_data <- data.frame(
  Property_Name = property_name,
  Address = address,
  Price = price,
  Area = area,
  Year_Built = year_built,
  Property_Type = property_type,
  Property_Tax = property_tax,
  Bedroom = bedroom,
  Full_Bathroom = full_bath,
  Partial_Bathroom = partial_bath,
  stringsAsFactors = FALSE
)


#################
# Data Collection
#################




# getting the last page number
last_page_element <- remDr$findElement(using = "xpath", "/html/body/div/div/div/div/section[2]/div/div[1]/div[3]/div/div/a[2]")


# Extract the text from the last page element which should be the page number
last_page_number <- as.numeric(last_page_element$getElementText())


# Initialising the dataframe
paris_data <- data.frame()


# Creating a loop to collect data from multiple pages
for (page_num in seq(from = 1, to = 1, by = 1)) {
  
  # Link of specific page
  paris_page <- paste0("https://www.sothebysrealty.com/eng/rentals/paris-il-fra")
  
  # Launching the page
  remDr$navigate(paris_page)
  
  # Letting the page load
  Sys.sleep(3)
  
  # Locate all property cards
  property_cards <- remDr$findElements(using = "xpath", "//div[contains(@class, 'Results-card__container') or contains(@class, 'Results-card__container--map')]")
  
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
  
  # Indicating the page number and the number of properties
  print(paste("Page:", page_num ))
  print(paste("No. of URLs:", length(property_urls)))
  
  # Gives time to collect the URLs
  Sys.sleep(10)
  
  # Creating the main loop
  for (url in property_urls) {
    tryCatch({
      # Navigate to the property's page
      remDr$navigate(url)
      Sys.sleep(3)  # Wait for the page to load completely
      
      # Scrolling the webpage
      remDr$executeScript(scrolling_script)
      
      Sys.sleep(8)  # Wait for the page to load completely
      
      # Click the "view more" button using XPath
      view_more_button <- remDr$findElement(using = "xpath", "//div[contains(@class, 'ListingFeatures__button-more')]")
      view_more_button$clickElement()
      
      # Property name 
      property_name <- tryCatch({
        remDr$findElement(using = "xpath", "//h2[contains(@class, 'ListingDescription__description-title') and contains(@class, 'h4') and contains(@class, 'u-color-dark-blue')]")$getElementText() %>% unlist()
      }, error = function(e){
        NA
      })
      
      # Find address
      address <- tryCatch({
        # Extract the address using XPath
        address_element <- remDr$findElement(using = "xpath", "//div[contains(@class, 'ContextualBar__address')]//span")
        # Get the text from the <span> element
        address_text <- address_element$getElementText()[[1]]}, error = function(e){
          NA
        })
      
      # Price
      price <- tryCatch({
        price_element <- remDr$findElement(using = "xpath", "//div[contains(text(), 'Listing Price')]/following-sibling::div[contains(@class, 'FeatureList__content')]")
        price_element$getElementText()[[1]]
      }, error = function(e){
        NA
      })
      
      
      # area in square feet
      area <- tryCatch({
        area_element <- remDr$findElement(using = "xpath", "//div[contains(text(), 'total sqft')]/following-sibling::div[contains(@class, 'FeatureList__content')]")
        area_element$getElementText()[[1]]
      }, error = function(e){
        NA
      })
      
      # area in square feet
      area1 <- tryCatch({
        area_element <- remDr$findElement(using = "xpath", "//span[contains(text(), 'Features')]/following-sibling::div[contains(@class, 'h5')]")
        area_element$getElementText()[[1]]
      }, error = function(e){
        NA
      })
      
      # Property type
      property_type <- tryCatch({
        property_type_element <- remDr$findElement(using = "xpath", "//div[contains(text(), 'Property type')]/following-sibling::div[contains(@class, 'FeatureList__content')]")
        property_type_element$getElementText()[[1]]
      }, error = function(e){
        NA
      })
      
      # Property Tax
      property_tax <- tryCatch({
        property_tax_element <- remDr$findElement(using = "xpath", "//div[contains(text(), 'property taxes')]/following-sibling::div[contains(@class, 'FeatureList__content')]")
        property_tax_element$getElementText()[[1]]
      }, error = function(e){
        NA
      })
      
      
      # Year built
      year_built <- tryCatch({
        year_built_element <- remDr$findElement(using = "xpath", "//p[contains(text(), 'Year Built')]/following-sibling::p[contains(@class, 'h4-lap u-padding-top-8')]")
        year_built_element$getElementText()[[1]]
      }, error = function(e){
        NA
      })
      
      # Total number of rooms
      total_room <- tryCatch({
        total_room_element <- remDr$findElement(using = "xpath", "//div[contains(text(), 'total rooms')]/following-sibling::div[contains(@class, 'FeatureList__content')]")
        total_room_element$getElementText()[[1]]
      }, error = function(e) {
        NA
      })
      
      
      # Number of bedrooms
      bedroom <- tryCatch({
        bedroom_element <- remDr$findElement(using = "xpath", "//div[contains(text(), 'Bedrooms')]/following-sibling::div[contains(@class, 'FeatureList__content')]")
        bedroom_element$getElementText()[[1]]
      }, error = function(e){
        NA
      })
      
      
      # Full bathrooms
      full_bath <- tryCatch({
        full_bath_element <- remDr$findElement(using = "xpath", "//div[contains(text(), 'Full Bathrooms')]/following-sibling::div[contains(@class, 'FeatureList__content')]")
        full_bath_element$getElementText()[[1]]
      }, error = function(e) {
        NA
      })
      
      # Partial Bathrooms
      partial_bath <- tryCatch({
        partial_bath_element <- remDr$findElement(using = "xpath", "//div[contains(text(), 'Partial Bathrooms')]/following-sibling::div[contains(@class, 'FeatureList__content')]")
        partial_bath_element$getElementText()[[1]]
      }, error = function(e) {
        NA
      })
      
      # Indicating the data collected from this property
      print(paste("Property Name:", property_name))
      print(paste("Address:", address))
      print(paste("Price:", price))
      print(paste("Area:", area))
      print(paste("Area:", area1))
      print(paste("Year Built:", year_built))
      print(paste("Property Type:", property_type))
      print(paste("Property Taxes:", property_tax))
      print(paste("Total Rooms:", total_room))
      print(paste("Bedroom:", bedroom))
      print(paste("Full Bathroom:", full_bath))
      print(paste("Partial Bathroom:", partial_bath))
      print(paste("Page:", page_num))
      
      # Creating dataset
      paris_property_data <- data.frame(
        Property_Name = property_name,
        Address = address,
        Price = price,
        Area = as.numeric(area),
        Area1 = area1,
        Year_Built = as.numeric(year_built),
        Property_Type = property_type,
        Property_Tax = property_tax,
        Bedroom = as.numeric(bedroom),
        Total_Room = as.numeric(total_room),
        Full_Bathroom = as.numeric(full_bath),
        Partial_Bathroom = as.numeric(partial_bath),
        stringsAsFactors = FALSE
      )
      
      # Storing property data to the main dataframe
      paris_data <- bind_rows(paris_data, paris_property_data)
      
      # Pause before moving to the next property
      Sys.sleep(4)
    }, error = function(e) {
      message("Error processing URL: ", url)
      message("Error details: ", e$message)
    })
  }
}
View(paris_data)
# Closing the server
remDr$close()
rs_driver_chrome$server$stop()

# Data cleaning

# Clean the data
paris_df <- paris_data %>%
  # Replace "Price Upon Request" with NA in the Price column
  mutate(Price = na_if(Price, "Price Upon Request"),
         # Replace NA with 0 in Full_Bathroom and Partial_Bathroom columns
         Full_Bathroom = ifelse(is.na(Full_Bathroom), 0, Full_Bathroom),
         Partial_Bathroom = ifelse(is.na(Partial_Bathroom), 0, Partial_Bathroom)) %>%
  # Clean the Price, Area1, and Property_Tax columns
  mutate(Price_cleaned = as.numeric(gsub("\\$|,", "", Price)),
         Area_cleaned = as.numeric(gsub(",| Sq Ft.", "", Area1)),
         Tax_cleaned = as.numeric(gsub("\\$|,|/Year", "", Property_Tax)),
         # Calculate total bathrooms
         Bathroom = Full_Bathroom + Partial_Bathroom) %>%
  # Select and rename the columns
  select(1, 2, Price = Price_cleaned, 6, 7, Area = Area_cleaned, Tax = Tax_cleaned, Total_room = Total_Room, Bedroom, Bathroom) %>% 
  # Changing 0 to NA
  mutate(Bathroom = na_if(Bathroom, 0),
         Area_code = as.numeric(gsub("Paris, Ile-De-France, | France", "", Address)))



paris_df2 <- paris_df %>%
  mutate(Property_Tax = str_extract(Property_Tax, "\\d+") %>% as.numeric(),
         Price = str_extract(Price, "\\d+") %>% as.numeric(),
         Area_Code = str_extract(Address, "\\d+") %>% as.numeric())
View(paris_df)

# Importing the data
paris_outdate <- read.csv("paris_sotheby_property.csv")

# Adding the new data to the old data
paris_df2 <- rbind(paris_outdate, paris_df2) %>% 
  distinct()



# Exporting as csv file
write.csv(paris_df, "paris_sotheby_property_rental.csv", row.names = FALSE)
View(paris_outdate)













































# Creating a loop to collect data from multiple pages
for (page_num in seq(from = 1, to = last_page_number, by = 1)) {
  
  # Link of specific page
  paris_page <- paste0("https://www.sothebysrealty.com/eng/sales/paris-il-fra/",page_num, "-pg")
  
  # Launching the page
  remDr$navigate(paris_page)
  
  # Letting the page load
  Sys.sleep(3)
  
  # Locate all property cards
  property_cards <- remDr$findElements(using = "xpath", "//div[contains(@class, 'Results-card__container') or contains(@class, 'Results-card__container--map')]")
  
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
  
  # Indicating the page number and the number of properties
  print(paste("No. of URLs:", length(property_urls)))
  
  # Gives time to collect the URLs
  Sys.sleep(10)
  
  # Creating the main loop
  for (url in property_urls) {
    tryCatch({
      # Navigate to the property's page
      remDr$navigate(url)
      Sys.sleep(3)  # Wait for the page to load completely
      
      # Scrolling the webpage
      remDr$executeScript(scrolling_script)
      Sys.sleep(7)  # Wait for the page to load completely
      
      # Property name 
      property_name <- tryCatch({
        remDr$findElement(using = "xpath", "//h2[contains(@class, 'ListingDescription__description-title') and contains(@class, 'h4') and contains(@class, 'u-color-dark-blue')]")$getElementText() %>% unlist()
      }, error = function(e){
        NA
      })
      
      
      # area in square feet
      area <- tryCatch({
        area_element <- remDr$findElement(using = "xpath", "//div[contains(text(), 'total sqft')]/following-sibling::div[contains(@class, 'FeatureList__content')]")
        area_element$getElementText()[[1]]
      }, error = function(e){
        NA
      })
      
      # area in square feet
      area1 <- tryCatch({
        area_element <- remDr$findElement(using = "xpath", "//span[contains(text(), 'Features')]/following-sibling::div[contains(@class, 'h5')]")
        area_element$getElementText()[[1]]
      }, error = function(e){
        NA
      })
      
      # Indicating the data collected from this property
      print(paste("Property Name:", property_name))
      print(paste("Area:", area))
      print(paste("Area:", area1))
      print(paste("Page:", page_num))
      
      # Creating dataset
      paris_property_data <- data.frame(
        Property_Name = property_name,
        Area = (area),
        Area1 = area1,
        stringsAsFactors = FALSE
      )
      
      # Storing property data to the main dataframe
      paris_data <- bind_rows(paris_data, paris_property_data)
      
    }, error = function(e) {
      message("Error processing URL: ", url)
      message("Error details: ", e$message)
    })
  }
}

