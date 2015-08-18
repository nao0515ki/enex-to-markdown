require 'nokogiri'
require 'reverse_markdown'
require 'date'
require 'pry'

def parse
  file = './notes.enex'
  parsed = Nokogiri::XML File.read file

  notes = parsed.xpath '//note'

  notes.map do |note|
    title = note.children.search('title').first.content
    content = note.children.search('content').first
    content = Nokogiri::XML(content.content).xpath('//div')
    if content.empty?
      content = note.children.search('content').first
      content = Nokogiri::XML content.content
      content = ReverseMarkdown.convert content.search('en-note').first.children.to_html
    else
      content = ReverseMarkdown.convert content.last.to_html
    end

    tags = note.children.search('tag').map(&:content)
    time = note.children.search('created').first.content
    time = DateTime.parse

    source = note.search('note-attributes').first.search('source-url')
    source = source.first.content unless source.empty?

    content = <<-END
#{title}
====================
Created At: #{time}
URL: #{source}
Tags: #{tags.join ','}

#{content}
END

    { title: title, content: content, note: note }
  end
end

def output_note(note)
  title = note[:title].gsub '/', "__"
  title = title[0..50] if title.length > 100
  file = "./notes/#{title}.txt"
  File.open(file, 'w') do |f|
    f.write note[:content]
  end
end

def delete(note_title)
  puts "Deleting '#{note_title}'"
  # command = "/usr/local/bin/geeknote remove --note \"#{note_title}\""
  # IO.popen(command, 'r+', err: [:child, :out]) do |io|
  #   io.puts 'Yes'
  #   puts io.readlines
  # end
  puts "Finished deleting #{note_title}"
end

def run
  notes = parse
  puts "There are #{notes.count} notes to migrate."

  notes.each do |note|
    output_note note
    delete note[:title]
  end
  puts 'All done migrating notes.'
end

run if __FILE__ == $PROGRAM_NAME
