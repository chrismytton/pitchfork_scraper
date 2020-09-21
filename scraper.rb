require 'bundler/setup'
require 'mechanize'
require 'time'
require 'scraperwiki'

agent = Mechanize.new
page = agent.get("https://pitchfork.com/reviews/albums/")

review_links = page.links_with(href: %r{^/reviews/albums/\w+})

review_links = review_links.drop(1).reject do |link|
  parent_classes = link.node.parent['class'].split
  parent_classes.any? { |p| %w[next-container page-number].include?(p) }
end

reviews = review_links.map do |link|
  review = link.click
  artist = review.search('.artist-links').text
  album = review.search('.single-album-tombstone__review-title').text
  label, year = review.search('.single-album-tombstone__meta').text.split('•').map(&:strip)
  reviewer = review.search('.authors-detail__display-name').text
  review_date = Time.parse(review.search('.pub-date')[0]['title'])
  score = review.search('.score').text.to_f
  {
    artist: artist,
    album: album,
    label: label,
    year: year,
    reviewer: reviewer,
    review_date: review_date,
    score: score
  }
end

reviews.each do |review|
  ScraperWiki.save_sqlite([:artist, :album], review)
end
