require "epathway_scraper"

scraper = EpathwayScraper.scrape_and_save(
  "https://cogc.cloud.infor.com/ePathway/epthprod",
  list_type: :advertising, state: "QLD"
)
