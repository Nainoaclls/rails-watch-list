require "open-uri"
require "json"

puts "Cleaning database..."
Bookmark.destroy_all
List.destroy_all
Movie.destroy_all

puts "Creating movies..."
begin
  url = "https://tmdb.lewagon.com/movie/top_rated"
  results = JSON.parse(URI.open(url).read)["results"]
  results.each do |movie|
    next if movie["overview"].blank?

    Movie.create!(
      title: movie["title"],
      overview: movie["overview"],
      poster_url: "https://image.tmdb.org/t/p/original#{movie['poster_path']}",
      rating: movie["vote_average"]
    )
  end
rescue StandardError => e
  puts "API unavailable (#{e.message}), using static movies"
  Movie.create!(title: "Wonder Woman 1984", overview: "Wonder Woman comes into conflict with the Soviet Union during the Cold War in the 1980s", poster_url: "https://image.tmdb.org/t/p/original/8UlWHLMpgZm9bx6QYh0NFoq67TZ.jpg", rating: 6.9)
  Movie.create!(title: "The Shawshank Redemption", overview: "Framed in the 1940s for double murder, upstanding banker Andy Dufresne begins a new life at the Shawshank prison", poster_url: "https://image.tmdb.org/t/p/original/q6y0Go1tsGEsmtFryDOJo3dEmqu.jpg", rating: 8.7)
  Movie.create!(title: "Titanic", overview: "101-year-old Rose DeWitt Bukater tells the story of her life aboard the Titanic.", poster_url: "https://image.tmdb.org/t/p/original/9xjZS2rlVxm8SFx8kPC3aIGCOYQ.jpg", rating: 7.9)
  Movie.create!(title: "Ocean's Eight", overview: "Debbie Ocean, a criminal mastermind, gathers a crew of female thieves to pull off the heist of the century.", poster_url: "https://image.tmdb.org/t/p/original/MvYpKlpFukTivnlBhizGbkAe3v.jpg", rating: 7.0)
end

puts "Created #{Movie.count} movies"

puts "Creating lists..."
lists = [
  {
    name: "Comedy",
    photo_url: "https://dnm.nflximg.net/api/v6/2DuQlx0fM4wd1nzqm5BFBi6ILa8/AAAAQaUiPLJpaxXAL-CGwnV-UUKic7arMB-yY4SY7enUbFgSksNG0BClmStlVX4vJO7EIkOODAr7zgP5aO0sPt3iG3XKNVEfbyLY-xQ4bMpzVHHRkSziQ5MnueXkDn4VXT2RfN7C4QEgg-2OvnrRVTfNluW7.jpg?r=936",
    filename: "comedy.jpg",
    content_type: "image/jpeg"
  },
  {
    name: "Action",
    photo_url: "https://deadline.com/wp-content/uploads/2025/05/Rambo-First-Blood.webp?w=681&h=383&crop=1",
    filename: "action.webp",
    content_type: "image/webp"
  }
]

lists.each do |attrs|
  list = List.create!(name: attrs[:name])
  begin
    photo = URI.parse(attrs[:photo_url]).open
    list.photo.attach(io: photo, filename: attrs[:filename], content_type: attrs[:content_type])
    puts "Created list #{list.name} with photo"
  rescue StandardError => e
    puts "Created list #{list.name} without photo (#{e.message})"
  end
end

puts "Created #{List.count} lists"
