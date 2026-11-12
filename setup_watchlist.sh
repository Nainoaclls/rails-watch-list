#!/bin/bash
set -e

echo "== 1. Modèles =="
[ -f app/models/movie.rb ]    || bin/rails g model Movie title overview:text poster_url rating:float
[ -f app/models/list.rb ]     || bin/rails g model List name
[ -f app/models/bookmark.rb ] || bin/rails g model Bookmark comment movie:references list:references

cat > app/models/movie.rb <<'EOF'
class Movie < ApplicationRecord
  has_many :bookmarks

  validates :title, presence: true, uniqueness: true
  validates :overview, presence: true
end
EOF

cat > app/models/list.rb <<'EOF'
class List < ApplicationRecord
  has_many :bookmarks, dependent: :destroy
  has_many :movies, through: :bookmarks

  validates :name, presence: true, uniqueness: true
end
EOF

cat > app/models/bookmark.rb <<'EOF'
class Bookmark < ApplicationRecord
  belongs_to :movie
  belongs_to :list

  validates :comment, length: { minimum: 6 }
  validates :movie_id, uniqueness: { scope: :list_id }
end
EOF

echo "== 2. Routes =="
cat > config/routes.rb <<'EOF'
Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "lists#index"

  resources :lists, only: [:index, :show, :new, :create] do
    resources :bookmarks, only: [:new, :create]
  end
  resources :bookmarks, only: [:destroy]
end
EOF

echo "== 3. Contrôleurs =="
cat > app/controllers/lists_controller.rb <<'EOF'
class ListsController < ApplicationController
  def index
    @lists = List.all
  end

  def show
    @list = List.find(params[:id])
  end

  def new
    @list = List.new
  end

  def create
    @list = List.new(list_params)
    if @list.save
      redirect_to list_path(@list)
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def list_params
    params.require(:list).permit(:name)
  end
end
EOF

cat > app/controllers/bookmarks_controller.rb <<'EOF'
class BookmarksController < ApplicationController
  before_action :set_list, only: [:new, :create]

  def new
    @bookmark = Bookmark.new
  end

  def create
    @bookmark = Bookmark.new(bookmark_params)
    @bookmark.list = @list
    if @bookmark.save
      redirect_to list_path(@list)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @bookmark = Bookmark.find(params[:id])
    @bookmark.destroy
    redirect_to list_path(@bookmark.list), status: :see_other
  end

  private

  def set_list
    @list = List.find(params[:list_id])
  end

  def bookmark_params
    params.require(:bookmark).permit(:comment, :movie_id)
  end
end
EOF

echo "== 4. Vues =="
mkdir -p app/views/lists app/views/bookmarks

cat > app/views/lists/index.html.erb <<'EOF'
<div class="container my-5">
  <div class="d-flex justify-content-between align-items-center mb-4">
    <h1>My watch lists</h1>
    <%= link_to "New list", new_list_path, class: "btn btn-primary" %>
  </div>

  <% if @lists.empty? %>
    <p class="text-muted">No lists yet. Create your first one!</p>
  <% else %>
    <div class="row">
      <% @lists.each do |list| %>
        <div class="col-md-4 mb-3">
          <%= link_to list_path(list), class: "text-decoration-none text-reset" do %>
            <div class="card h-100 shadow-sm">
              <div class="card-body">
                <h5 class="card-title"><%= list.name %></h5>
                <p class="card-text text-muted"><%= pluralize(list.movies.count, "movie") %></p>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
  <% end %>
</div>
EOF

cat > app/views/lists/new.html.erb <<'EOF'
<div class="container my-5" style="max-width: 600px;">
  <h1>New list</h1>
  <%= simple_form_for @list do |f| %>
    <%= f.input :name %>
    <%= f.button :submit, class: "btn btn-primary" %>
  <% end %>
  <%= link_to "← All lists", lists_path, class: "d-block mt-3" %>
</div>
EOF

cat > app/views/lists/show.html.erb <<'EOF'
<div class="container my-5">
  <div class="d-flex justify-content-between align-items-center mb-4">
    <h1><%= @list.name %></h1>
    <%= link_to "Add a movie", new_list_bookmark_path(@list), class: "btn btn-primary" %>
  </div>

  <% if @list.bookmarks.empty? %>
    <p class="text-muted">No movies yet. Add your first one!</p>
  <% else %>
    <div class="row">
      <% @list.bookmarks.each do |bookmark| %>
        <div class="col-sm-6 col-md-4 col-lg-3 mb-4">
          <div class="card movie-card h-100 shadow-sm">
            <%= image_tag bookmark.movie.poster_url, class: "card-img-top", alt: bookmark.movie.title %>
            <div class="card-body d-flex flex-column">
              <h5 class="card-title"><%= bookmark.movie.title %></h5>
              <p class="text-muted mb-1">⭐ <%= bookmark.movie.rating.to_f.round(1) %></p>
              <p class="card-text flex-grow-1"><em>"<%= bookmark.comment %>"</em></p>
              <%= link_to "Remove", bookmark_path(bookmark),
                    data: { turbo_method: :delete, turbo_confirm: "Remove this movie from the list?" },
                    class: "btn btn-outline-danger btn-sm" %>
            </div>
          </div>
        </div>
      <% end %>
    </div>
  <% end %>

  <%= link_to "← All lists", lists_path %>
</div>
EOF

cat > app/views/bookmarks/new.html.erb <<'EOF'
<div class="container my-5" style="max-width: 600px;">
  <h1>Add a movie to <%= @list.name %></h1>
  <%= simple_form_for [@list, @bookmark] do |f| %>
    <%= f.association :movie, prompt: "Choose a movie" %>
    <%= f.input :comment %>
    <%= f.button :submit, "Add to list", class: "btn btn-primary" %>
  <% end %>
  <%= link_to "← Back to #{@list.name}", list_path(@list), class: "d-block mt-3" %>
</div>
EOF

echo "== 5. Style des affiches =="
cat > app/assets/stylesheets/components/_movie_card.scss <<'EOF'
.movie-card img {
  height: 380px;
  object-fit: cover;
}
EOF
grep -q 'movie_card' app/assets/stylesheets/components/_index.scss || echo '@import "movie_card";' >> app/assets/stylesheets/components/_index.scss

echo "== 6. Seed =="
cat > db/seeds.rb <<'EOF'
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
EOF

echo "== 7. Base de données et tests =="
bin/rails db:migrate
bin/rails db:migrate RAILS_ENV=test
bin/rails db:seed
bundle exec rspec

echo "== Terminé =="
