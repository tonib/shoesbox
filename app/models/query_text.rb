
# Definition of a songs search string
class QueryText

  ARTIST_PREFIX = 'artist:'
  SONG_PREFIX = 'song:'
  ALBUM_PREFIX = 'album:'
  PATH_PREFIX = 'path:'

  PREFIXES = [ ARTIST_PREFIX , SONG_PREFIX , ALBUM_PREFIX , PATH_PREFIX ]

  # Constructor
  # [+query_text+] The simple query string to parse
  def initialize(query_text)

    @prefix = nil
    @search_text = nil

    return if !query_text
    query_text = query_text.strip
    return if query_text.empty?

    # Try to get the search prefix:
    @prefix = PREFIXES.find { |prefix| query_text.start_with?(prefix) }
    if @prefix
      query_text = query_text[ @prefix.length .. -1 ]
    end
    @search_text = query_text.strip

  end

  # True is the query string is empty
  def empty?
    return !@search_text || @search_text.empty?
  end

  # Apply the filter to a search songs Relation
  # [+relation+] Relation to filter
  # [+returns+] The filtered relation
  def apply_filter(relation)

    return relation if empty?

    # Text to search:
    like_text = '%' + @search_text + '%'
    # Path to search (normalize directory separators)
    path_like = like_text.gsub('\\' , '/')

    case @prefix
      when ARTIST_PREFIX
        relation = relation.where( 'artists.name like ?' , like_text )
      when SONG_PREFIX
        relation = relation.where( 'songs.name like ?' , like_text )
      when PATH_PREFIX
        relation = relation.where( 'songs.path like ?' , path_like )
      when ALBUM_PREFIX
        relation = relation.where( 'albums.name like ?' , path_like )
      else
        relation = relation
          .where( 'albums.name like ? or artists.name like ? or ' +
            'songs.name like ? or songs.path like ?' , like_text , like_text ,
            like_text , path_like )
    end

    return relation

  end

  # Filter a songs search by a composite query string
  # [+query_text+] The composite query text
  # [+relation+] The Relation to filter
  # [+returns+] The filtered Relation
  def self.apply_composite_query(query_text, relation)

    return relation if !query_text

    query_text.split(';').each do |part|
      query = QueryText.new(part)
      relation = query.apply_filter(relation)
    end

    return relation
  end

end
