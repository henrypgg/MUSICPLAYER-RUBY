require 'gosu'

TOP_COLOR = Gosu::Color.new(0xFF1EB1FA)
BOTTOM_COLOR = Gosu::Color.new(0xFF1D4DB5)

module ZOrder
  BACKGROUND, PLAYER, UI = *0..2
end

class ArtWork
  attr_accessor :bmp

  def initialize(file, width, height)
    @bmp = Gosu::Image.new(file, {retro: true, tileable: true})
    @width, @height = width, height
  end

  def draw(x, y)
    @bmp.draw(x, y, ZOrder::PLAYER, @width / @bmp.width.to_f, @height / @bmp.height.to_f)
  end
end

class Track
  attr_accessor :title, :location

  def initialize(title, location)
    @title = title
    @location = "tracks/#{location}" # path to track file
  end
end

class Album
  attr_accessor :title, :artist, :artwork, :tracks

  def initialize(title, artist, artwork, artwork_width, artwork_height)
    @title = title
    @artist = artist
    @artwork = ArtWork.new("images/#{artwork}", artwork_width, artwork_height)
    @tracks = []
  end

  def add_track(track)
    @tracks << track
  end
end

class MusicPlayerMain < Gosu::Window
  ALBUM_ARTWORK_WIDTH = 100     # Width for artwork
  ALBUM_ARTWORK_HEIGHT = 100    # Height for artwork
  ALBUM_SPACING = 200           # Space between albums
  TITLE_Y_OFFSET = 110          # Vertical offset for the title below the artwork
  BUTTON_WIDTH = 50            # Button width (adjusted to be more usable)
  BUTTON_HEIGHT = 50           # Button height (adjusted to be more usable)

  BUTTON_X = 375               # X position of Play/Pause button
  BUTTON_Y = 450               # Y position of Play/Pause button
  NEXT_BUTTON_X = 500          # X position of Next button
  PREV_BUTTON_X = 250          # X position of Previous button

  def initialize
    super 800, 600
    self.caption = "Music Player"

    @albums = load_albums('albums.txt')
    @current_album = nil
    @current_track = nil
    @song = nil
    @track_font = Gosu::Font.new(20)
    @album_font = Gosu::Font.new(16)
    @is_playing = false

    # Load Play, Pause, Next, and Previous button images
    @play_button = Gosu::Image.new("images/button/playbtn.png")
    @pause_button = Gosu::Image.new("images/button/pausebtn.png")
    @next_button = Gosu::Image.new("images/button/nextbtn.png")
    @prev_button = Gosu::Image.new("images/button/prevbtn.png")
  end

  # Reads albums and tracks from the albums.txt file
  def load_albums(filename)
    albums = []
    File.open(filename, 'r') do |file|
      num_albums = file.gets.to_i
      num_albums.times do
        title = file.gets.strip
        artist = file.gets.strip
        artwork = file.gets.strip
        album = Album.new(title, artist, artwork, ALBUM_ARTWORK_WIDTH, ALBUM_ARTWORK_HEIGHT)

        num_tracks = file.gets.to_i
        num_tracks.times do
          track_title = file.gets.strip
          track_location = file.gets.strip
          album.add_track(Track.new(track_title, track_location))
        end
        albums << album
      end
    end
    albums
  end

  # Draws a colored background
  def draw_background
    Gosu.draw_rect(0, 0, 800, 600, TOP_COLOR, ZOrder::BACKGROUND)
    Gosu.draw_rect(0, 0, 800, 600, BOTTOM_COLOR, ZOrder::BACKGROUND)
  end

  # Draws albums, tracks, and the Play/Pause button
  def draw
    draw_background

    x = 50
    y = 50
    @albums.each_with_index do |album, index|
      album.artwork.draw(x, y)
      @album_font.draw_text("#{album.title} by #{album.artist}", x, y + TITLE_Y_OFFSET, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
      x += ALBUM_SPACING # Move to the next album horizontally

      if @current_album == index
        track_y = y + ALBUM_ARTWORK_HEIGHT + 40
        album.tracks.each_with_index do |track, track_index|
          color = (track == @current_track) ? Gosu::Color::YELLOW : Gosu::Color::WHITE
          @track_font.draw_text(track.title, 50, track_y + track_index * 30, ZOrder::PLAYER, 1.0, 1.0, color)
        end
      end
    end

    if @current_track
      @track_font.draw_text("Now playing: #{@current_track.title}", 50, 550, ZOrder::UI, 1.0, 1.0, Gosu::Color::GREEN)
    end

    # Draw Play/Pause button based on the current state
    button_image = @is_playing ? @pause_button : @play_button
    button_image.draw(BUTTON_X, BUTTON_Y, ZOrder::UI, BUTTON_WIDTH / button_image.width.to_f, BUTTON_HEIGHT / button_image.height.to_f)

    # Draw Next and Previous buttons
    @next_button.draw(NEXT_BUTTON_X, BUTTON_Y, ZOrder::UI, BUTTON_WIDTH / @next_button.width.to_f, BUTTON_HEIGHT / @next_button.height.to_f)
    @prev_button.draw(PREV_BUTTON_X, BUTTON_Y, ZOrder::UI, BUTTON_WIDTH / @prev_button.width.to_f, BUTTON_HEIGHT / @prev_button.height.to_f)
  end

  # Detects if a certain area has been clicked
  def area_clicked(leftX, topY, rightX, bottomY)
    mouse_x >= leftX && mouse_x <= rightX && mouse_y >= topY && mouse_y <= bottomY
  end

  # Handles mouse clicks for selecting albums, tracks, and Play/Pause, Next, and Previous buttons
  def button_down(id)
    case id
    when Gosu::MsLeft
      x = 50
      y = 50

      # Check if an album is clicked
      @albums.each_with_index do |album, index|
        if area_clicked(x, y, x + ALBUM_ARTWORK_WIDTH, y + ALBUM_ARTWORK_HEIGHT)
          @current_album = index
          @current_track = nil
          return
        end
        x += ALBUM_SPACING # Move to the next album horizontally

        if @current_album == index
          album.tracks.each_with_index do |track, track_index|
            if area_clicked(50, y + ALBUM_ARTWORK_HEIGHT + 40 + track_index * 30, 600, y + ALBUM_ARTWORK_HEIGHT + 70 + track_index * 30)
              play_track(track, album)
              @current_track = track
              return
            end
          end
        end
      end

      # Check if Play/Pause button is clicked
      if area_clicked(BUTTON_X, BUTTON_Y, BUTTON_X + BUTTON_WIDTH, BUTTON_Y + BUTTON_HEIGHT)
        toggle_play_pause
      end

      # Check if Next button is clicked
      if area_clicked(NEXT_BUTTON_X, BUTTON_Y, NEXT_BUTTON_X + BUTTON_WIDTH, BUTTON_Y + BUTTON_HEIGHT)
        next_album
      end

      # Check if Previous button is clicked
      if area_clicked(PREV_BUTTON_X, BUTTON_Y, PREV_BUTTON_X + BUTTON_WIDTH, BUTTON_Y + BUTTON_HEIGHT)
        previous_album
      end
    end
  end

  # Plays the selected track and stops any previously playing track
  def play_track(track, album)
    @song.stop if @song
    @song = Gosu::Song.new(track.location)
    @song.play(false)
    @is_playing = true
  end

  # Toggles between play and pause states
  def toggle_play_pause
    if @is_playing
      @song.pause
      @is_playing = false
    else
      @song.play(false)
      @is_playing = true
    end
  end

  # Goes to the next album
  def next_album
    @current_album = (@current_album + 1) % @albums.length
    @current_track = nil
  end

  # Goes to the previous album
  def previous_album
    @current_album = (@current_album - 1) % @albums.length
    @current_track = nil
  end

  def update
    # Nothing needed here as mouse interactions are handled in button_down
  end

  def needs_cursor?
    true
  end
end

class MusicPlayerMain < Gosu::Window
  ALBUM_ARTWORK_WIDTH = 100     # Width for artwork
  ALBUM_ARTWORK_HEIGHT = 100    # Height for artwork
  ALBUM_SPACING = 200           # Space between albums
  TITLE_Y_OFFSET = 110          # Vertical offset for the title below the artwork
  BUTTON_WIDTH = 50            # Play/Pause button width (adjusted to be more usable)
  BUTTON_HEIGHT = 50           # Play/Pause button height (adjusted to be more usable)

  BUTTON_X = 375               # X position of Play/Pause button
  BUTTON_Y = 450               # Y position of Play/Pause button
  PREV_BUTTON_X = 300          # X position for Previous button
  NEXT_BUTTON_X = 450          # X position for Next button

  def initialize
    super 800, 600
    self.caption = "Music Player"

    @albums = load_albums('albums.txt')
    @current_album = nil
    @current_track = nil
    @song = nil
    @track_font = Gosu::Font.new(20)
    @album_font = Gosu::Font.new(16)
    @is_playing = false

    # Load Play, Pause, Next, and Previous button images
    @play_button = Gosu::Image.new("images/button/playbtn.png")
    @pause_button = Gosu::Image.new("images/button/pausebtn.png")
    @prev_button = Gosu::Image.new("images/button/prevbtn.png")
    @next_button = Gosu::Image.new("images/button/nextbtn.png")
  end

  def draw
    draw_background

    x = 50
    y = 50
    @albums.each_with_index do |album, index|
      album.artwork.draw(x, y)
      @album_font.draw_text("#{album.title} by #{album.artist}", x, y + TITLE_Y_OFFSET, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
      x += ALBUM_SPACING

      if @current_album == index
        track_y = y + ALBUM_ARTWORK_HEIGHT + 40
        album.tracks.each_with_index do |track, track_index|
          color = (track == @current_track) ? Gosu::Color::YELLOW : Gosu::Color::WHITE
          @track_font.draw_text(track.title, 50, track_y + track_index * 30, ZOrder::PLAYER, 1.0, 1.0, color)
        end
      end
    end

    if @current_track
      @track_font.draw_text("Now playing: #{@current_track.title}", 50, 550, ZOrder::UI, 1.0, 1.0, Gosu::Color::GREEN)
    end

    # Draw Play/Pause button based on the current state
    button_image = @is_playing ? @pause_button : @play_button
    button_image.draw(BUTTON_X, BUTTON_Y, ZOrder::UI, BUTTON_WIDTH / button_image.width.to_f, BUTTON_HEIGHT / button_image.height.to_f)

    # Draw Previous and Next buttons
    @prev_button.draw(PREV_BUTTON_X, BUTTON_Y, ZOrder::UI, BUTTON_WIDTH / @prev_button.width.to_f, BUTTON_HEIGHT / @prev_button.height.to_f)
    @next_button.draw(NEXT_BUTTON_X, BUTTON_Y, ZOrder::UI, BUTTON_WIDTH / @next_button.width.to_f, BUTTON_HEIGHT / @next_button.height.to_f)
  end

  def area_clicked(leftX, topY, rightX, bottomY)
    mouse_x >= leftX && mouse_x <= rightX && mouse_y >= topY && mouse_y <= bottomY
  end

  def button_down(id)
    case id
    when Gosu::MsLeft
      x = 50
      y = 50

      # Check if an album is clicked
      @albums.each_with_index do |album, index|
        if area_clicked(x, y, x + ALBUM_ARTWORK_WIDTH, y + ALBUM_ARTWORK_HEIGHT)
          @current_album = index
          @current_track = nil
          return
        end
        x += ALBUM_SPACING

        if @current_album == index
          album.tracks.each_with_index do |track, track_index|
            if area_clicked(50, y + ALBUM_ARTWORK_HEIGHT + 40 + track_index * 30, 600, y + ALBUM_ARTWORK_HEIGHT + 70 + track_index * 30)
              play_track(track, album)
              @current_track = track
              return
            end
          end
        end
      end

      # Check if Play/Pause button is clicked
      if area_clicked(BUTTON_X, BUTTON_Y, BUTTON_X + BUTTON_WIDTH, BUTTON_Y + BUTTON_HEIGHT)
        toggle_play_pause
      end

      # Check if Previous button is clicked
      if area_clicked(PREV_BUTTON_X, BUTTON_Y, PREV_BUTTON_X + BUTTON_WIDTH, BUTTON_Y + BUTTON_HEIGHT)
        skip_previous
      end

      # Check if Next button is clicked
      if area_clicked(NEXT_BUTTON_X, BUTTON_Y, NEXT_BUTTON_X + BUTTON_WIDTH, BUTTON_Y + BUTTON_HEIGHT)
        skip_next
      end
    end
  end

  def play_track(track, album)
    @song.stop if @song
    @song = Gosu::Song.new(track.location)
    @song.play(false)
    @is_playing = true
  end

  def toggle_play_pause
    if @is_playing
      @song.pause
      @is_playing = false
    else
      @song.play(false)
      @is_playing = true
    end
  end

  def skip_previous
    return unless @current_album

    album = @albums[@current_album]
    current_index = album.tracks.index(@current_track)
    return if current_index.nil? || current_index == 0

    @current_track = album.tracks[current_index - 1]
    play_track(@current_track, album)
  end

  def skip_next
    return unless @current_album

    album = @albums[@current_album]
    current_index = album.tracks.index(@current_track)
    return if current_index.nil? || current_index == album.tracks.length - 1

    @current_track = album.tracks[current_index + 1]
    play_track(@current_track, album)
  end

  def update
    # Nothing needed here as mouse interactions are handled in button_down
  end

  def needs_cursor?
    true
  end
end

MusicPlayerMain.new.show if __FILE__ == $0

