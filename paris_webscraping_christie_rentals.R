# Webscraping Parisian Rental Properties in Christie's
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
paris_url <- "https://www.christiesrealestate.com/rentals/paris-pa-fra"

# Launching the website
remDr$navigate(paris_url)


# Scrolling script
scrolling_script <- scrolling_script <- "
    (function() {
        let lastScrollHeight = 0;
        let scrollCount = 0;
        const maxScrolls = 50;  // Maximum number of scroll attempts
        const scrollStep = 200; // Amount to scroll per step
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

#################
# Data Collection
#################

# Launching the website
remDr$navigate(paris_url)


# getting the last page number
last_page_element <- remDr$findElement(using = "xpath", "/html/body/div[2]/div/div/div/div[1]/div[2]/div[4]/div[5]/div/div/a[10]")


# Extract the text from the last page element which should be the page number
last_page_number <- as.numeric(last_page_element$getElementText())


# Initialising the dataframe
paris_data <- data.frame()


# Creating a loop to collect data from multiple pages
for (page_num in seq(from = 1, to = 3, by = 1)) {
  
  # Link of specific page
  paris_page <- paste0("https://www.christiesrealestate.com/rentals/paris-pa-fra/",page_num, "-pg")

  # Launching the page
  remDr$navigate(paris_page)
  
  # Letting the page load
  Sys.sleep(3)
  
  # Scrolling the webpage
  remDr$executeScript(scrolling_script)
  
  Sys.sleep(10)  # Wait for the page to load completely
  
  # Get all elements with the desired class
  url_elements <- remDr$findElements(using = "css selector", value = ".listing-item__tab-content-contact")
  
  # Extract the href attributes
  property_urls <- sapply(url_elements, function(element) {
    element$getElementAttribute("href")[[1]]
  })
  
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
      Sys.sleep(5)  # Wait for the page to load completely
      
      # Scrolling the webpage
      remDr$executeScript(scrolling_script)
      
      Sys.sleep(8)  # Wait for the page to load completely
      
      # Property name 
      property_name <- tryCatch({
        remDr$findElement(using = "xpath", "//div[contains(@class, 'main-address')]")$getElementText() %>% unlist()
      }, error = function(e){
        NA
      })
      
      # Find Area Code
      area_code <- tryCatch({
        remDr$findElement(using = "xpath", "//span[contains(@class, 'postal-code')]")$getElementText() %>% unlist()
      }, error = function(e){
        NA
      })
      
      # Price
      price <- tryCatch({
        price_element <- remDr$findElement(using = "xpath", "//span[contains(@class, 'price__value')]")$getElementText() %>% unlist()
      }, error = function(e){
        NA
      })
      
      # area in square feet
      area <- tryCatch({
        # Locate the <dd> element that contains "Sq Ft."
        value_element <- remDr$findElement(using = "xpath", "//dd[contains(text(), 'Sq Ft')]")
        
        # Extract the text from the <dd> element
        value_text <- value_element$getElementText()[[1]]
        
      }, error = function(e) {
        message("Error: ", e$message)
        cleaned_value <- NA
      })
      
      # Property type
      property_type <- tryCatch({
        # Locate the <span> element
        span_element <- remDr$findElement(using = "xpath", "//span[@style='text-transform: lowercase;']")
        
        # Extract the text from the <span> element
        full_text <- span_element$getElementText()[[1]]
        
      }, error = function(e) {
        message("Error: ", e$message)
        full_text <- NA
      })
      
      
      # Retrieve the year built
      year_built <- tryCatch({
        # Find all <dd> elements with the class "listing-info__value"
        elements <- remDr$findElements(using = "xpath", "//dd[@class='listing-info__value']")
        
        # Initialize a variable to store the year built
        year_built <- NA
        
        # Loop through each element and check if it contains exactly 4 digits
        for (el in elements) {
          text <- el$getElementText()[[1]]
          if (grepl("^\\d{4}$", text)) {
            year_built <- text
            break  # Exit the loop once the correct element is found
          }
        }
        
        # If no 4-digit year is found, year_built remains NA
        year_built
      }, error = function(e) {
        NA
      })
      
      # Number of bedrooms
      bedroom <- tryCatch({
        # Find the element using a more specific XPath that includes the class attribute
        bedroom_element <- remDr$findElement(using = "xpath", "//span[@class='image-caption__property-details__item' and contains(text(), 'BD')]")
        # Get the text of the element
        bedroom_element$getElementText()[[1]]
      }, error = function(e) {
        # Return NA in case of an error
        NA
      })
      
      
      # Bathrooms
      bathroom <- tryCatch({
        bathroom_element <- remDr$findElement(using = "xpath", "//span[@class='image-caption__property-details__item' and contains(text(), 'BA')]")
        bathroom_element$getElementText()[[1]]
      }, error = function(e) {
        NA
      })
      
      
      # Indicating the data collected from this property
      print(paste("Property Name:", property_name))
      print(paste("Area Code:", area_code))
      print(paste("Price:", price))
      print(paste("Area:", area))
      print(paste("Year Built:", year_built))
      print(paste("Property Type:", property_type))
      print(paste("Bedroom:", bedroom))
      print(paste("Bathroom:", bathroom))
      print(paste("Page:", page_num))
      
      # Creating dataset
      paris_property_data <- data.frame(
        Property_Name = property_name,
        Area_code = area_code,
        Price = price,
        Area = (area),
        Year_Built = (year_built),
        Property_Type = property_type,
        Bedroom = (bedroom),
        Bathroom = (bathroom),
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
paris_df <- paris_data %>% 
  mutate(
    Area_code = as.numeric(Area_code),  
    Price = as.numeric(gsub("\\$|,", "", Price)),
    Area = round(as.numeric(gsub(",| Sq Ft.", "", Area)), 2),
    Year_Built = as.numeric(Year_Built),  
    Bedroom = as.numeric(gsub(" BD", "", Bedroom)),
    Bathroom_duplicate = gsub(" BA", "", Bathroom)
  ) %>% 
  separate(Bathroom_duplicate, into = c("Full", "Partial"), sep = "/", convert = TRUE) %>% 
  mutate(Full = ifelse(is.na(Full), 0, Full),
         Partial = ifelse(is.na(Partial), 0, Partial)) %>% 
  mutate(Bathroom2 = Full + Partial) %>% 
  select(., -Bathroom, -Full, -Partial, Bathroom = Bathroom2)

# Exporting as csv file
write.csv(paris_df, "paris_christie_property_rental.csv", row.names = FALSE)
View(paris_outdate)


