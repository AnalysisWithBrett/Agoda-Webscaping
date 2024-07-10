<img src="https://gifdb.com/images/high/pixel-art-super-mario-computer-amwdq1xi8bgz0omx.gif" alt="MasterHead" width="1000" height="500">

# Webscraping Data from Agoda using RSelenium

## Description
This project involves web scraping data from Agoda, a popular online travel agency and metasearch engine for hotels and vacation rentals. The task was performed using RSelenium, a powerful R package that provides bindings for the Selenium WebDriver, allowing automated web browsing and data extraction.

## Table of Contents
- [Objectives](#objectives)
- [Installation](#installation)
- [RSelenium Set-up](#rselenium-set-up)
- [Usage](#usage)
  - [Library and Work Directory](#library-and-work-directory)
  - [Activating RSelenium](#activating-rselenium)
  - [Launching Agoda](#launching-agoda)
  - [Creating a Scrolling Script](#creating-a-scrolling-script)
- [Building the Components for My Automated Webscraping](#building-the-components-for-my-automated-webscraping)
  - [Clicking the "Top Reviewed" Button](#clicking-the-top-reviewed-button)
  - [Collecting Property URLs](#collecting-property-urls)
  - [Moving to the Next Page](#moving-to-the-next-page)
  - [Components That Collect Variables](#components-that-collect-variables)
  - [Collecting Room Types and Prices (Challenging Part for Me)](#collecting-room-types-and-prices-challenging-part-for-me)
  - [Click Show More Button](#click-show-more-button)
  - [After Data Collection](#after-data-collection)
  - [The Super Loop](#the-super-loop)
  - [Closing the Server](#closing-the-server)
- [Data Cleaning](#data-cleaning)
- [Exporting the Data](#exporting-the-data)
- [Credits](#credits)

## Objectives
The main objective of this project was to extract comprehensive information about various properties listed on Agoda, specifically focusing on:
- Property names
- Addresses
- Number of reviews
- Score ratings (out of 10)
- Star ratings (out of 5)
- Room types 
- Prices (in US dollars)

Additionally, the goal was to automate the data collection process, ensuring smooth navigation through each page without errors. After the automated extraction, the data is manually cleaned to ensure accuracy and consistency.

## Installation
To run this project locally, you need to have R installed along with the following libraries:
- RSelenium
- tidyverse

You can install these libraries in R:
```bash
install.packages("RSelenium")
install.packages("tidyverse")
```

## RSelenium Set-up
Before you start, I would highly recommend you to watch this [video](https://youtu.be/GnpJujF9dBw?si=Aigiyof_XQVYEF4_), which will walk you through how to properly install RSelenium on your machine to perform web automation.

## Usage
### Library and Work Directory
This step can help you locate your file after you export your data as a csv or excel file. To do this, you can do the following:
```bash
# Library
library(RSelenium)
library(tidyverse)

# Setting work directory
setwd('C://Users//hoybr//Documents//data projects//indonesia project//agoda')
```
The code above is an example. Make sure your slashes are double when you copy the folder path.
### Activating RSelenium
This part is where you launch a remote web driver to navigate through the Agoda website and configure RSelenium to interact with the web browser. The first code will list all the chromedriver versions you have. If you do not have the chromedriver that matches with the version of your chrome, I highly recommend you to watch this [video](https://www.youtube.com/watch?v=BnY4PZyL9cg), which will guide you through the the solution to get your selenium servers up and running.
```bash
# Getting the versions of chromedriver
binman::list_versions("chromedriver")


# Creating the chrome driver
rs_driver_chrome <- rsDriver(
  browser = "chrome",
  chromever = "126.0.6478.126"
)

# Access the client object - helps control selenium
remDr <- rs_driver_chrome$client
```
### Launching Agoda
You can use any url. I simply typed Sanur in the search bar in Agoda, and copied the link and pasted it in R with quotation marks.
```bash
# Url of Sanur
sanur_url <- "https://www.agoda.com/search?guid=b10b3e58-e943-4a71-a575-70a95b0dd0ca&asq=u2qcKLxwzRU5NDuxJ0kOF3T91go8JoYYMxAgy8FkBH1BN0lGAtYH25sdXoy34qb9o0l7KdSelo7k%2F7FlfCgu8OgryV5WLksAi0YUzbbahlDuvqz3jLoMuyaRE7CKv%2FNkdKT8zx5W5BioMdUuG%2F%2Fqg83wDgMWghx%2F1T04xY6GCGQLLtFYGE809Nke6UCgrsgCQYl3V1iy9nb%2B0qxM0R6Qmg%3D%3D&area=26634&tick=638559732012&locale=en-us&ckuid=c6c2a39a-3fcc-4661-8901-bb37935ae16c&prid=0&currency=USD&correlationId=0c211340-abac-4c31-8d9a-12712bf4c704&analyticsSessionId=8522598931351326311&pageTypeId=1&realLanguageId=1&languageId=1&origin=GB&stateCode=YOR&cid=-1&userId=c6c2a39a-3fcc-4661-8901-bb37935ae16c&whitelabelid=1&loginLvl=0&storefrontId=3&currencyId=7&currencyCode=USD&htmlLanguage=en-us&cultureInfoName=en-us&machineName=am-pc-4h-acm-web-user-58d46fc4b6-lpvnd&trafficGroupId=4&sessionId=vfl2rfihhzbt50gjvhi5pvpq&trafficSubGroupId=4&aid=130243&useFullPageLogin=true&cttp=4&isRealUser=true&mode=production&browserFamily=Edge+%28Chromium%29+for+Windows&cdnDomain=agoda.net&checkIn=2024-10-09&checkOut=2024-10-10&rooms=1&adults=1&children=0&priceCur=USD&los=1&textToSearch=Sanur&travellerType=0&familyMode=off&ds=bkx66szIZiYnzr9m&productType=-1"

# Launching the website
remDr$navigate(sanur_url)
```
### Creating a scrolling script
This part uses JavaScript code to help you scroll down the Agoda webpage. This will help load all the properties after scrolling down the webpage, which will help in collecting all the data within the page. If you want to adjust the scrolling speed, you can change the values in "scrolStep" and "scrollInterval", which is set to 1600 and 1400, respectively. I chose this speed as it will give time for the webpage to load.
```bash
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
```
## Building the components for my automated webscraping
The code for this is a loop and it is nearly 200 lines long, so I thought it would be better for me to walk you through the code in chunks.

### Clicking the "Top Reviewed" Button
This step is my personal choice. I noticed that the properties are arranged randomly in the default page so I created this code to click the "Top Reviewed" button as this will reorder the properties from highest to lowest number of reviews. This step is important for the loop.

![Sample](https://github.com/AnalysisWithBrett/Agoda-Webscaping/blob/main/top%20reviewed.png)

Here is the following code that presses the "Top Reviewed Button":
```bash
# Clicking the top view button
remDr$findElement(using = 'xpath', "//div[contains(@class, 'Box-sc-kv6pi1-0') and contains(@class, 'cRTyjI')]")$clickElement()
Sys.sleep(4)
```

### Collecting Property URLs
You will need to collect all the URLs from each page so that RSelenium can go through each property to collect data. The first step is to use the scrolling script so that all the property elements are loaded within the page.
```bash
# Scroll the webpage to load all properties
  remDr$executeScript(scrolling_script)
  Sys.sleep(40)  # Adjust sleep time if necessary to ensure all content is loaded
```

The next step is to collect all the URLs from each property.

```
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
```
### Moving to the next page
After collecting data from the first page, you'll need to move on to the next page. To facilitate this, I created a for loop to ensure that the code clicks the "Next" button if the page number is greater than 1.
```bash
for (page in 1:6) {  # Change the range as needed to cover the required pages
  # Only click the "Next" button after the first page
  if (page > 1) {
    for (i in 1:(page - 1)) {
      remDr$findElement(using = "xpath", "//button[contains(@class, 'Buttonstyled__ButtonStyled-sc-5gjk6l-0') and contains(@class, 'jyyvGo') and contains(@class, 'btn') and contains(@class, 'pagination2__next')]")$clickElement()
      
      # Scroll the webpage to load all properties
      remDr$executeScript(scrolling_script)
      Sys.sleep(40)  # Adjust sleep time if necessary to ensure all content is loaded
    }
  }}
```

### Components that collect variables
When it comes to webscraping, it is important to understand how HTML works, so I would highly recommend you to [video](https://www.youtube.com/watch?v=Dkm1d4uMp34&t=157s). Otherwise you can follow through my code below.

The objective is to gather specific variables, such as property name, address, number of reviews, score rating, and star rating, while ensuring that the code continues to loop even when it encounters an error. Errors typically arise when an expected element is missing.

Why does this happen? While browsing properties on Agoda, you may notice that some properties lack reviews, score ratings, and star ratings. As a result, those elements are not present for these properties, causing RSelenium to fail. To prevent this from happening, I used the "tryCatch" function in R to make sure that the code continues to run after encountering a missing element from a property, while giving a default value, such as "No reviews" or "0".
```bash
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
```
### Collecting Room Types and Prices (Challenging part for me)
I find this part particularly challenging due to Agoda's setup. To help you understand, I will illustrate the issue:

![Sample](https://github.com/AnalysisWithBrett/Agoda-Webscaping/blob/main/deluxe%20garden.png)

The image above illustrates Agoda's layout for each room type. Each room type is represented by its own red box, and within each red box, there are smaller blue-highlighted boxes. For instance, when collecting the room type and prices, you might receive one room type, such as "Deluxe Garden," and three different price entries. This becomes problematic when a property page features multiple room types, as it complicates the task of matching prices to their respective room types. To address this, I created a code that counts the number of blue boxes within each red room type box and then multiply the room type data by this count to align with the number of prices available. Here is a code that demonstrates this:

```bash
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
```
### Click Show More Button
In Agoda, you will notice that there is an option to press the "Show more" button within the room type box, which will reveal more prices. The code below will make sure that the code clicks the "Show More" button before it collects the prices and roomtype data.
```bash
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
```
### After Data Collection
The data collected is then organised in a dataframe, while ensuring that the data from all variables matches with the number of data of the variable price.
```bash
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
```
### The Super Loop
That's all the components explained. You can check out the [R Code](https://github.com/AnalysisWithBrett/Agoda-Webscaping/blob/main/agoda%20hotel.R) to see the whole code. I just want to mention that these codes within the loop is used to help you track the progress of the webscraping algorithm.
```bash
# Indicating the page number 
print(paste("Page:", page))

# Indicating the number of links in the page
print(paste("There are", length(property_urls), "links"))
print(first_property)

print(paste("Property Number:", length(unique(agoda_data$Property_Name))))
print(paste("Processed property:", property_name, "with", length(agoda_property_data$Property_Name), "entries"))
```
### Closing the server
After collecting the data, you can close the RSelenium server with this code:
```bash
# Closing the server
remDr$close()
rs_driver_chrome$server$stop()
```
## Data Cleaning
This part is where I manually cleaned the data. I made sure that data are in the right format.
```bash
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
```
## Exporting the Data
Once you finish cleaning the data, you can export the data in CSV format.
```bash
# Exporting as csv file
write.csv(agoda_cleaned, "agoda_data.csv")
```
## Credits
This project is developed by [Brett Hoy](https://github.com/AnalysisWithBrett). I personally would like to thank [Samer Hijjazi](https://www.youtube.com/@SamerHijjazi) for his videos, which helped me overcome many challenges with Webscraping using RSelenium. If you have any questions or suggestions, feel free to contact me.

