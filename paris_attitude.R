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
paris_url <- "https://www.parisattitude.com/rent-apartment/furnished-rental/index,rentals.aspx?p=2"

# Launching the website
remDr$navigate(paris_url)


# Scrolling script
scrolling_script <- scrolling_script <- "
    (function() {
        let lastScrollHeight = 0;
        let scrollCount = 0;
        const maxScrolls = 50;  // Maximum number of scroll attempts
        const scrollStep = 1500; // Amount to scroll per step
        const scrollInterval = 1000; // Time between scroll steps in milliseconds
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



##########################################################################
# Testing (Make sure to test your code here before starting the loop)
#########################################################################


# Locate all property cards
property_cards <- remDr$findElements(using = "xpath", "//div[contains(@class, 'col-xs-12') and contains(@class, 'col-sm-6') and contains(@class, 'col-md-6') and contains(@class, ' col-lg-4')]")

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


# Click the button to open energy and gas emissions
energy_button <- remDr$findElement(using = "xpath", "//i[contains(@class, 'hidden-xs')]")
energy_button$clickElement()



# Property name 
property_name <- tryCatch({
  remDr$findElement(using = "xpath", "//div[@class='pa-flex-mobile-order-3']//h1")$getElementText() %>% unlist()
}, error = function(e){
  "0"
})

# Find address
address <- tryCatch({
  remDr$findElement(using = "xpath", "//h2[contains(@class, 'address')]")$getElementText() %>% unlist()
}, error = function(e){
  "0"
})

# Price
price <- tryCatch({
  price_element <- remDr$findElement(using = "xpath", "//span[contains(@id, 'smallerprice')]")
  price_element$getElementText()[[1]]
}, error = function(e){
  "0"
})

# More price options
price2 <- tryCatch({
  price_element <- remDr$findElement(using = "xpath", "//span[contains(@id, 'noPromotionPrice')]")
  price_element$getElementText()[[1]]
}, error = function(e){
  "0"
})

# No availability message
no_available <- tryCatch({
  no_available_element <- remDr$findElement(using = "xpath", "//div[contains(@class, 'inner')]")
  no_available_element$getElementText()[[1]]
}, error = function(e){
  "0"
})



# number of occupants
occupants <- tryCatch({
  occupants_element <- remDr$findElement(using = "xpath", "//span[contains(@itemprop, 'maximumAttendeeCapacity')]")
  occupants_element$getElementText()[[1]]
}, error = function(e){
  "0"
})

# Floor number
floor <- tryCatch({
  floor_element <- remDr$findElement(using = "xpath", "//div[contains(@class, 'resume-item') and .//span[contains(@class, 'fa-building-o')]]")
  floor_text <- floor_element$getElementText()[[1]]
}, error = function(e){
  "0"
})

# availability
availability <- tryCatch({
  availability_element <- remDr$findElement(using = "xpath", "//div[contains(@class, 'info-line')]")
  availability_element$getElementText()[[1]]
}, error = function(e){
  "0"
})


# arrondissement
arrondissement <- tryCatch({
  arrondissement_element <- remDr$findElement(using = "xpath", "//h4[contains(@class, 'amiri')]")
  arrondissement_element$getElementText()[[1]]
}, error = function(e){
  "0"
})



# energy class
energy <- tryCatch({
  current_value_element <- remDr$findElement(using = "xpath", "//div[contains(@class, 'diag-current epd')]//div[@class='diag-current-value']")
  current_value <- current_value_element$getElementText()[[1]]
}, error = function(e){
  "0"
})


# GHG class
ghg <- tryCatch({
  ghg_element <- remDr$findElement(using = "xpath", "//div[contains(@class, 'diag-current ghg')]//div[@class='diag-current-value']")
  ghg_element$getElementText()[[1]]
}, error = function(e) {
  "0"
})


# Indicating the data collected from this property
print(paste("Property Name:", property_name))
print(paste("Address:", address))
print(paste("Price:", price))
print(paste("Occupants:", occupants))
print(paste("Floor:", floor))
print(paste("Availability:", availability))
print(paste("Arrondissement:", arrondissement))
print(paste("Energy:", energy))
print(paste("GHG:", ghg))

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

# JavaScript to scroll down one step
scroll_script2 <- "window.scrollBy(0, 4200);"
remDr$executeScript(scroll_script2)

# Initialising the dataframe
paris_data <- data.frame()


# Creating a loop to collect data from multiple pages
for (page_num in seq(from = 1, to = 68, by = 1)) {
  
  # Link of specific page
  paris_page <- paste0("https://www.parisattitude.com/rent-apartment/furnished-rental/index,rentals.aspx?p=", page_num)
  
  # Launching the page
  remDr$navigate(paris_page)
  
  # Letting the page load
  Sys.sleep(3)
  
  # Scrolling the webpage
  remDr$executeScript(scrolling_script)
  
  Sys.sleep(10)  # Wait for the page to load completely
  
  # Locate all property cards
  property_cards <- remDr$findElements(using = "xpath", "//div[contains(@class, 'col-xs-12') and contains(@class, 'col-sm-6') and contains(@class, 'col-md-6') and contains(@class, ' col-lg-4')]")
  
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
      
      # Check if the specific element exists
      element_exists <- tryCatch({
        element <- remDr$findElement(using = "xpath", "//span[@style='right:5px;position:absolute;']//i[@class='hidden-xs fa fa-chevron-down']")
        TRUE
      }, error = function(e) {
        FALSE
      })
      
      if (element_exists) {
        # Scroll to the specific element
        remDr$executeScript("arguments[0].scrollIntoView(true);", list(element))
        
        # Scroll slightly up
        remDr$executeScript("window.scrollBy(0, -100);")  # Adjust the scroll amount as needed
      } else {
        # Scroll down the webpage
        remDr$executeScript(scrolling_script)
      }
      
      Sys.sleep(5)  # Wait for the page to load completely
      
      # Click the button to open energy and gas emissions
      energy_button <- remDr$findElement(using = "xpath", "//i[contains(@class, 'hidden-xs')]")
      energy_button$clickElement()
      
      # Property name 
      property_name <- tryCatch({
        remDr$findElement(using = "xpath", "//div[@class='pa-flex-mobile-order-3']//h1")$getElementText() %>% unlist()
      }, error = function(e){
        "0"
      })
      
      # Find address
      address <- tryCatch({
        remDr$findElement(using = "xpath", "//h2[contains(@class, 'address')]")$getElementText() %>% unlist()
      }, error = function(e){
        "0"
      })
      
      # Price
      price <- tryCatch({
        price_element <- remDr$findElement(using = "xpath", "//span[contains(@id, 'smallerprice')]")
        price_element$getElementText()[[1]]
      }, error = function(e){
        "0"
      })
      
      # More price options
      price2 <- tryCatch({
        price_element <- remDr$findElement(using = "xpath", "//span[contains(@id, 'noPromotionPrice')]")
        price_element$getElementText()[[1]]
      }, error = function(e){
        "0"
      })
      
      # New price
      new_price <- tryCatch({
        newprice_element <- remDr$findElement(using = "xpath", "//text[contains(@class, 'newPrice')]")
        newprice_element$getElementText()[[1]]
      }, error = function(e){
        "0"
      })
      
      # No availability message
      no_available <- tryCatch({
        no_available_element <- remDr$findElement(using = "xpath", "//div[contains(@class, 'inner')]")
        no_available_element$getElementText()[[1]]
      }, error = function(e){
        "0"
      })
      
      # number of occupants
      occupants <- tryCatch({
        occupants_element <- remDr$findElement(using = "xpath", "//span[contains(@itemprop, 'maximumAttendeeCapacity')]")
        occupants_element$getElementText()[[1]]
      }, error = function(e){
        "0"
      })
      
      # Floor number
      floor <- tryCatch({
        floor_element <- remDr$findElement(using = "xpath", "//div[contains(@class, 'resume-item') and .//span[contains(@class, 'fa-building-o')]]")
        floor_text <- floor_element$getElementText()[[1]]
      }, error = function(e){
        "0"
      })
      
      # availability
      availability <- tryCatch({
        availability_element <- remDr$findElement(using = "xpath", "//div[contains(@class, 'info-line')]")
        availability_element$getElementText()[[1]]
      }, error = function(e){
        "0"
      })
      
      
      # arrondissement
      arrondissement <- tryCatch({
        arrondissement_element <- remDr$findElement(using = "xpath", "//h4[contains(@class, 'amiri')]")
        arrondissement_element$getElementText()[[1]]
      }, error = function(e){
        "0"
      })
      
      
      
      # energy class
      energy <- tryCatch({
        current_value_element <- remDr$findElement(using = "xpath", "//div[contains(@class, 'diag-current epd')]//div[@class='diag-current-value']")
        current_value <- current_value_element$getElementText()[[1]]
      }, error = function(e){
        "0"
      })
      
      
      # GHG class
      ghg <- tryCatch({
        ghg_element <- remDr$findElement(using = "xpath", "//div[contains(@class, 'diag-current ghg')]//div[@class='diag-current-value']")
        ghg_element$getElementText()[[1]]
      }, error = function(e) {
        "0"
      })
      
      # Description
      description <- tryCatch({
        description_element <- remDr$findElement(using = "xpath", "//div[contains(@class, 'descr')]//p")
        description_element$getElementText()[[1]]
      }, error = function(e) {
        "0"
      })
      
      # Indicating the data collected from this property
      print(paste("Property Name:", property_name))
      print(paste("Address:", address))
      print(paste("Price:", price))
      print(paste("Price 2:", price2))
      print(paste("New Price:", new_price))
      print(paste("Availability:", no_available))
      print(paste("Occupants:", occupants))
      print(paste("Floor:", floor))
      print(paste("Availability:", availability))
      print(paste("Arrondissement:", arrondissement))
      print(paste("Energy:", energy))
      print(paste("GHG:", ghg))
      print(paste("Page:", page_num))
      
      # Creating dataset
      paris_property_data <- data.frame(
        Property_Name = property_name,
        Address = address,
        Price = price,
        Price2 = price2,
        New_price = new_price,
        no_available = no_available,
        Occupants = occupants,
        Floor = floor,
        Availability = availability,
        Energy = energy,
        GHG = ghg,
        Description = description,
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

