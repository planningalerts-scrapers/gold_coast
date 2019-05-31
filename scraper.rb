require "epathway_scraper"

scraper = EpathwayScraper.scrape(
  "https://cogc.cloud.infor.com/ePathway/epthprod",
  list_type: :advertising
) do |record|
  # Throw away the first part of the address which contains lot number
  record["address"] = record["address"].split(", ")[1..-1].join(", ")
  EpathwayScraper.save(record)
end
