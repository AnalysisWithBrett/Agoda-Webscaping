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

# Initialising the dataframe
paris_data <- data.frame()

paris_data <- (paris_data[1:3677,])


# Creating a loop to collect data from multiple pages
for (page_num in seq(from = 133, to = 136, by = 1)) {
  
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
      Sys.sleep(6)
      
      if (element_exists) {
        # Scroll to the specific element
        remDr$executeScript("arguments[0].scrollIntoView(true);", list(element))
        
        # Scroll slightly up
        remDr$executeScript("window.scrollBy(0, -140);")  # Adjust the scroll amount as needed
      } else {
        # Scroll down the webpage
        remDr$executeScript(scrolling_script)
      }
      
      Sys.sleep(3)  # Wait for the page to load completely
      
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
        Arrondissement = arrondissement,
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
      Sys.sleep(1)
    }, error = function(e) {
      message("Error processing URL: ", url)
      message("Error details: ", e$message)
    })
  }
}




# Closing the server
remDr$close()
rs_driver_chrome$server$stop()

# Data cleaning

# Clean the data
# Function to extract the second word
extract_second_word <- function(x) {
  words <- unlist(strsplit(x, " "))
  if (length(words) >= 2) {
    return(words[2])
  } else {
    return(NA)
  }
}

# Function to extract the number of bedrooms
extract_bedroom_number <- function(x) {
  match <- regmatches(x, regexpr("[0-9]+", x))
  if (length(match) > 0) {
    return(as.numeric(match))
  } else {
    return(NA)
  }
}

# Function to extract the area
extract_area <- function(x) {
  match <- regmatches(x, regexpr("[0-9]+m²", x))
  if (length(match) > 0) {
    return(match)
  } else {
    return(NA)
  }
}

# Function to extract the address
extract_address <- function(x) {
  match <- regmatches(x, regexpr("[0-9]+m² - (.*)", x, perl = TRUE))
  if (length(match) > 0) {
    return(sub("[0-9]+m² - ", "", match))
  } else {
    return(NA)
  }
}

# Function to extract the postal code
extract_postal_code <- function(x) {
  match <- regmatches(x, regexpr("[0-9]{5}", x))
  if (length(match) > 0) {
    return(match)
  } else {
    return(NA)
  }
}

# Function to extract the floor number
extract_floor <- function(x) {
  match <- regmatches(x, regexpr("[0-9]{1}", x))
  if (length(match) > 0) {
    return(match)
  } else {
    return(NA)
  }
}

# Function to extract the arrondissement number
extract_arrondissement <- function(text) {
  # Use regular expression to find the arrondissement number within parentheses
  match <- str_extract(text, "\\(\\D*\\s*\\d{1,2}\\)")
  if (!is.na(match)) {
    # Extract only the arrondissement number from the match
    return(as.numeric(str_extract(match, "\\d{1,2}")))
  }
  return(NA)
}


# Function to extract and format the availability date
extract_and_format_date <- function(text) {
  if (text == "0") {
    return("not available")
  }
  
  # Extract the date in the format m/d/yyyy or d/m/yyyy
  date_match <- str_extract(text, "\\b\\d{1,2}/\\d{1,2}/\\d{4}\\b")
  
  if (!is.na(date_match)) {
    # Split the date into components
    date_parts <- strsplit(date_match, "/")[[1]]
    
    # Add leading zeros to single-digit day and month
    formatted_date <- sprintf("%02d/%02d/%04d", as.numeric(date_parts[1]), as.numeric(date_parts[2]), as.numeric(date_parts[3]))
    return(formatted_date)
  } else {
    return("now")
  }
}

# Function to extract elevator information
extract_elevator <- function(text) {
  if (str_detect(text, "with elevator")) {
    return(1)
  } else if (str_detect(text, "without elevator")) {
    return(0)
  } else {
    return(NA)
  }
}

# Function to extract numbers from text
extract_numbers <- function(text) {
  # Use regular expression to find the number
  match <- str_extract(text, "\\d+")
  return(as.numeric(match))
}

# Expand the code to include the extraction of the number of bedrooms, area, and address
paris_df <- paris_data %>% 
  select(Property_Name, Address, Arrondissement, Price, Price2, New_price, Occupants, Availability, Floor, Energy, GHG, Description) %>% 
  mutate(
    Property_type = sapply(strsplit(Property_Name, " "), `[`, 2),
    Bedroom = sapply(sub(" -.*", "", Property_Name), extract_bedroom_number),
    Area = sapply(Property_Name, extract_area),
    Address2 = sapply(Property_Name, extract_address),
    Postal_code = sapply(Address, extract_postal_code),
    Price_cleaned = as.numeric(gsub("From | €", "", Price)),
    Price2_cleaned = sapply(Price2, extract_numbers),
    New_price_clean = as.numeric(New_price),
    Floor_number = sapply(Floor, extract_floor),
    Arrondissement2 = sapply(Arrondissement, extract_arrondissement),
    Energy = as.numeric(Energy),
    GHG = as.numeric(GHG),
    Available_date = sapply(Availability, extract_and_format_date),
    Elevator = sapply(Floor, extract_elevator)
  ) %>% mutate(Area = as.numeric(gsub("m²", "", Area))) %>% 
  mutate(Price_cleaned = ifelse(is.na(Price_cleaned), 0, Price_cleaned),
         New_price_clean = ifelse(is.na(New_price_clean), 0, New_price_clean),
         Floor_number = ifelse(is.na(Floor_number), 0, Floor_number),
         Bedroom = ifelse(is.na(Bedroom), 1, Bedroom),
         Energy = na_if(Energy, 0),
         GHG = na_if(GHG, 0)) %>% 
  mutate(total_price = Price_cleaned + New_price_clean) %>% 
  select(Address = Address2, Postal_code, Arrondissement = Arrondissement2, Area, Price = total_price, 
         Price2_cleaned, Bedroom, Occupants, Floor = Floor_number, Energy, GHG, Elevator, 
         Available_date, Description) %>% 
  mutate(Price = na_if(Price, 0)) %>% 
  mutate(Price = coalesce(Price, Price2_cleaned)) %>% 
  select(-Price2_cleaned)

# Viewing the data
View(paris_df)
View(paris_data)



# Exporting as csv file
write.csv(paris_df, "paris_attitude_clean.csv", row.names = FALSE, fileEncoding = "UTF-8")
View(paris_data)

