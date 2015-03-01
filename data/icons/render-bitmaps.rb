#!/usr/bin/env ruby

require "rexml/document"
require "fileutils"
include REXML
INKSCAPE = '/usr/bin/inkscape'
SRC = "./"

def renderit(file,explicit)
  svg = Document.new(File.new("#{SRC}/#{file}", 'r'))
  #puts "DEBUG: #{file}"
  svg.root.each_element("//g[contains(@inkscape:label,'baseplate')]") do |icon|
    if icon.attributes['inkscape:groupmode']=='layer' #only look inside layers, there may be pasted groups
      context = icon.elements["text[@inkscape:label='context']/tspan"].nil? ? 'blank' : icon.elements["text[@inkscape:label='context']/tspan"].text
      icon_name = icon.elements["text[@inkscape:label='icon-name']/tspan"].nil? ? 'blank' : icon.elements["text[@inkscape:label='icon-name']/tspan"].text
      puts "#{file}:#{icon.attributes['inkscape:label']}  #{context}/#{icon_name}"
      icon.each_element("rect") do |box|
        dir = "hicolor/#{box.attributes['width']}x#{box.attributes['height']}/#{context}"
        out = "#{dir}/#{icon_name.gsub(/$/,'.png')}"
        cmd = "#{INKSCAPE} -i #{box.attributes['id']} -e #{out} #{SRC}/#{file} > /dev/null 2>&1"
        FileUtils.makedirs(dir) unless File.exists?(dir)
        if (!explicit && File.exists?(out))
          print "-" #skip if PNG exists
        elsif (box.attributes['width']=="256")
          system(cmd)
          print "."
          dir = "hicolor/512x512/#{context}"
          out = "#{dir}/#{icon_name.gsub(/$/,'.png')}"
          cmd = "#{INKSCAPE} -i #{box.attributes['id']} -d 180 -e #{out} #{SRC}/#{file} > /dev/null 2>&1"
          system(cmd)
          print "*"          
        else
          system(cmd)
          print "."
        end
      end
      puts ''
    end
  end
end

if (ARGV[0].nil?) #render all SVGs
  system("mkdir hicolor/") unless File.exists?('hicolor')
  puts "Rendering from SVGs in #{SRC}"
  Dir.foreach(SRC) do |file|
    renderit(file, false) if file.match(/svg$/)
  end
  puts "\nrendered all SVGs"
else #only render the SVG passed
  file = "#{ARGV[0]}.svg"
  if (File.exists?("#{SRC}/#{file}"))
    renderit(file, true)
    puts "\nrendered #{file}"
  else
    puts "[E] No such file (#{file})"
  end
end
