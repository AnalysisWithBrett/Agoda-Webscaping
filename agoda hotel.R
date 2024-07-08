# Agoda webscraping
library(RSelenium)
library(tidyverse)

# setting working directory
setwd('C://Users//hoybr//Documents//data projects//indonesia project//booking.com')

# Getting the versions of chromedriver
binman::list_versions("chromedriver")


# Creating the chrome driver
rs_driver_chrome <- rsDriver(
  browser = "chrome",
  chromever = "126.0.6478.126"
)

# Access the client object - helps control selenium
remDr <- rs_driver_chrome$client


# Url of Sanur
sanur_url <- "https://www.agoda.com/search?guid=b10b3e58-e943-4a71-a575-70a95b0dd0ca&asq=u2qcKLxwzRU5NDuxJ0kOF3T91go8JoYYMxAgy8FkBH1BN0lGAtYH25sdXoy34qb9o0l7KdSelo7k%2F7FlfCgu8OgryV5WLksAi0YUzbbahlDuvqz3jLoMuyaRE7CKv%2FNkdKT8zx5W5BioMdUuG%2F%2Fqg83wDgMWghx%2F1T04xY6GCGQLLtFYGE809Nke6UCgrsgCQYl3V1iy9nb%2B0qxM0R6Qmg%3D%3D&area=26634&tick=638559732012&locale=en-us&ckuid=c6c2a39a-3fcc-4661-8901-bb37935ae16c&prid=0&currency=USD&correlationId=0c211340-abac-4c31-8d9a-12712bf4c704&analyticsSessionId=8522598931351326311&pageTypeId=1&realLanguageId=1&languageId=1&origin=GB&stateCode=YOR&cid=-1&userId=c6c2a39a-3fcc-4661-8901-bb37935ae16c&whitelabelid=1&loginLvl=0&storefrontId=3&currencyId=7&currencyCode=USD&htmlLanguage=en-us&cultureInfoName=en-us&machineName=am-pc-4h-acm-web-user-58d46fc4b6-lpvnd&trafficGroupId=4&sessionId=vfl2rfihhzbt50gjvhi5pvpq&trafficSubGroupId=4&aid=130243&useFullPageLogin=true&cttp=4&isRealUser=true&mode=production&browserFamily=Edge+%28Chromium%29+for+Windows&cdnDomain=agoda.net&checkIn=2024-10-09&checkOut=2024-10-10&rooms=1&adults=1&children=0&priceCur=USD&los=1&textToSearch=Sanur&travellerType=0&familyMode=off&ds=bkx66szIZiYnzr9m&productType=-1"

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


# Launching the website
remDr$navigate(sanur_url)

# Initialize an empty dataframe
agoda_data <- data.frame()

# Define the super loop for multiple pages
for (page in 1:6) {  # Change the range as needed to cover the required pages
  
  # Clicking the top view button
  remDr$findElement(using = 'xpath', "//div[contains(@class, 'Box-sc-kv6pi1-0') and contains(@class, 'cRTyjI')]")$clickElement()
  Sys.sleep(4)
  
  # Indicating the page number 
  print(paste("Page:", page))
  
  # Scroll the webpage to load all properties
  remDr$executeScript(scrolling_script)
  Sys.sleep(40)  # Adjust sleep time if necessary to ensure all content is loaded
  
  # Only click the "Next" button after the first page
  if (page > 1) {
    for (i in 1:(page - 1)) {
      remDr$findElement(using = "xpath", "//button[contains(@class, 'Buttonstyled__ButtonStyled-sc-5gjk6l-0') and contains(@class, 'jyyvGo') and contains(@class, 'btn') and contains(@class, 'pagination2__next')]")$clickElement()
      
      # Scroll the webpage to load all properties
      remDr$executeScript(scrolling_script)
      Sys.sleep(40)  # Adjust sleep time if necessary to ensure all content is loaded
    }
  }
  
  # Find all elements matching the given XPath pattern
  property_containers <- remDr$findElements(using = 'xpath', '//*[@id="contentContainer"]/div/ol/li/div/div/a')
  
  # Extract the 'href' attribute from each element
  property_urls <- sapply(property_containers, function(element) {
    href <- element$getElementAttribute("href") %>% unlist()
    if (length(href) == 0) {
      return(NA)  # Return NA if href is NULL or empty
    }
    return(href)
  })
  
  # Remove NA values and duplicate URLs
  property_urls <- unique(na.omit(property_urls))
  
  # First property name
  first_property <- remDr$findElement(using = 'xpath', '//h3[contains(@class, "sc-jrAGrp") and contains(@class, "sc-kEjbxe") and contains(@class, "eDlaBj") and contains(@class, "dscgss")]')$getElementText() %>% unlist()
  
  # Indicating the number of links in the page
  print(paste("There are", length(property_urls), "links"))
  print(first_property)

  
  
  
  # Loop through each property URL
  for (url in property_urls) {
    tryCatch({
      # Navigate to the property's page
      remDr$navigate(url)
      Sys.sleep(4)  # Wait for the page to load completely
      
      # Locate and click all "Show more" buttons
      buttons <- remDr$findElements(using = 'xpath', "//div[@data-selenium='MasterRoom-showMoreLessButton']")
      for (button in buttons) {
        tryCatch({
          button$clickElement()
          Sys.sleep(2)  # Wait for content to load or changes to happen
          buttons <- remDr$findElements(using = 'xpath', "//div[@data-selenium='MasterRoom-showMoreLessButton']")
        }, error = function(e) {
          message("Error clicking button: ", e$message)
        })
      }
      
      # Find property name
      property_name <- tryCatch({
        remDr$findElement(using = 'xpath', "//h2[@data-selenium='hotel-header-name']")$getElementText() %>% unlist()
      }, error = function(e) {
        "Unknown Property"
      })
      
      # Extracting address
      address <- tryCatch({
        remDr$findElement(using = "xpath", "//span[contains(@class, 'Spanstyled__SpanStyled-sc-16tp9kb-0') and contains(@class, 'gwICfd') and contains(@class, 'kite-js-Span') and contains(@class, 'HeaderCerebrum__Address')]")$getElementText() %>% unlist()
      }, error = function(e) {
        "Address not found"
      })
      
      # Find reviews
      reviews <- tryCatch({
        reviews_element <- remDr$findElement(using = "xpath", "//p[contains(@class, 'Typographystyled__TypographyStyled-sc-j18mtu-0') and contains(@class, 'Hkrzy') and contains(@class, 'kite-js-Typography')]")
        reviews_element$getElementText() %>% unlist()
      }, error = function(e) {
        "No reviews found"
      })
      
      # Find score rating
      score_rating <- tryCatch({
        score_element <- remDr$findElement(using = "xpath", "//span[contains(@class, 'sc-jrAGrp') and contains(@class, 'sc-kEjbxe') and contains(@class, 'fzPhrN') and contains(@class, 'ehWyCi')]")
        score_element$getElementText() %>% unlist()
      }, error = function(e) {
        "0"
      })
      
      # Find star rating
      star_rating <- tryCatch({
        star_element <- remDr$findElement(using = "xpath", "//span[contains(@class, 'sc-idOhPF') and contains(@class, 'kGntgQ')]")
        star_element$getElementText() %>% unlist()
      }, error = function(e) {
        "0"
      })
      
      # Find room types
      room_elements <- remDr$findElements(using = "xpath", "//span[contains(@class, 'MasterRoom__HotelName')]")
      room_types <- sapply(room_elements, function(elem) elem$getElementText() %>% unlist())
      
      # Locate all main table containers using their class
      main_tables <- remDr$findElements(using = 'xpath', "//div[contains(@class, 'ChildRoomsList') and contains(@class, 'ChildRoomsList--flex') and contains(@class, 'ChildRoomsList--multi')]")
      
      # Initialize a list to store the number of rows for each table
      number_of_rows_list <- list()
      
      # Loop through each main table and count the number of rows
      for (i in seq_along(main_tables)) {
        main_table <- main_tables[[i]]
        row_elements <- main_table$findChildElements(using = 'xpath', ".//div[contains(@class, 'ChildRoomsList-roomCell') and contains(@class, 'ChildRoomsList-roomCell-price') and contains(@class, 'relativeCell')]")
        number_of_rows <- length(row_elements)
        number_of_rows_list[[i]] <- number_of_rows
      }
      
      rows <- number_of_rows_list %>% unlist()
      
      # Initialize a vector for room types
      room <- c()
      for (i in seq_along(rows)) {
        room <- c(room, rep(room_types[i], rows[i]))
      }
      
      # Find prices
      price_elements <- remDr$findElements(using = "xpath", "//span[contains(@class, 'Spanstyled__SpanStyled-sc-16tp9kb-0') and contains(@class, 'gwICfd') and contains(@class, 'kite-js-Span') and contains(@class, 'pd-price') and contains(@class, 'PriceDisplay')]")
      prices <- sapply(price_elements, function(elem) elem$getElementText() %>% unlist())
      
      # Ensure room and price lengths match
      if (length(room) == length(prices)) {
        agoda_property_data <- data.frame(
          Property_Name = rep(property_name, length(prices)),
          Address = rep(address, length(prices)),
          Score_Rating = rep(score_rating, length(prices)),
          Reviews = rep(reviews, length(prices)),
          Star_Rating = rep(star_rating, length(prices)),
          Price = prices,
          RoomType = room,
          stringsAsFactors = FALSE
        )
        agoda_data <- bind_rows(agoda_data, agoda_property_data)
      } else {
        warning("Mismatch between room types and prices for URL: ", url)
      }
      
      print(paste("Property Number:", length(unique(agoda_data$Property_Name))))
      print(paste("Processed property:", property_name, "with", length(agoda_property_data$Property_Name), "entries"))
      Sys.sleep(4)
    }, error = function(e) {
      message("Error processing URL: ", url)
      message("Error details: ", e$message)
    })
  }
  
  
  
  
  # After processing all property URLs on the current page, navigate back to the initial URL
  remDr$navigate(sanur_url)
  Sys.sleep(10)  # Additional sleep to ensure the page is fully loaded before next iteration
}

# Closing the server
remDr$close()
rs_driver_chrome$server$stop()





# Cleaning the data
str(agoda_data)
View(agoda_data)

# Converting to numerical values
agoda_data$Price <- as.numeric(agoda_data$Price)



# Function to clean reviews
clean_reviews <- function(reviews) {
  cleaned_reviews <- gsub("[^0-9]", "", reviews)  # Remove non-numeric characters
  cleaned_reviews <- ifelse(cleaned_reviews == "", "0", cleaned_reviews)  # Replace empty strings with "0"
  as.numeric(cleaned_reviews)  # Convert to numeric
}

# Function to clean star rating (extracting only the first number)
clean_star_rating <- function(star_rating) {
  cleaned_rating <- gsub("[^0-9]", "", star_rating)  # Remove non-numeric characters
  cleaned_rating <- substr(cleaned_rating, 1, 1)  # Keep only the first character
  cleaned_rating <- ifelse(cleaned_rating == "", "0", cleaned_rating)  # Replace empty strings with "0"
  as.numeric(cleaned_rating)  # Convert to numeric
}


# Apply cleaning functions to the data frame
agoda_cleaned <- agoda_data %>%
  mutate(
    Reviews = clean_reviews(Reviews),
    Star_Rating = clean_star_rating(Star_Rating)
  )

# Converting to numerical values
agoda_cleaned$Score_Rating <- as.numeric(agoda_cleaned$Score_Rating)

# Exporting as csv file
write.csv(agoda_cleaned, "agoda_data.csv")





