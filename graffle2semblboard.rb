#!/usr/bin/env ruby

# Converts OmniGraffle documents to JSON documents, which specify nodes and 
# how they're linked together.

# Hat tip to iloveitaly on GitHub:
# https://gist.github.com/1487305/2988ae1b0cc74afd78589b0cce9054259cbba876

require 'rubygems'
require 'json'

# Import the scripting bridge so we can communicate with OmniGraffle
require 'osx/cocoa'
include OSX
OSX.require_framework 'ScriptingBridge'

# Replace "OmniGrafflePro" with "OmniGraffle" if you don't have Pro
graffle = SBApplication.applicationWithBundleIdentifier_("com.omnigroup.OmniGrafflePro")

$shape_list = []
$line_list = []

# First, iterate over all nodes, generating tags for them all
# and creating the hash that represents them

# This also merges in the user data dictionary for each node, which you can
# set up in OmniGraffle and lets you set up custom fields for each node.
# This might be a Pro only feature? Not sure. Never not used Pro.

graffle.windows[0].document.canvases[0].layers[0].shapes.select do |s|  
  
  # Set the identifying tag for each node to its text.
  # If it doesn't have text, generate a random identifier.
  
  text = s.text.get.to_s
  if text == "":
    text = rand(100000).to_s
  end
  
  s.tag = text
  
  # Now generate the hash for it, merging in the user data
  
  $shape_list << {:positionX => s.origin.x.to_i, :positionY => s.origin.y.to_i, :id => "Node-" + s.tag}.merge(s.userData)
  
end

# Once we've gone through all nodes, we look at each line connecting them,
# give them a tag, and then create the hash that defines it

graffle.windows[0].document.canvases[0].layers[0].shapes.select do |s|

  s.outgoingLines.each do |l|
    
    # Generate an identifier for this link based on the tags of the nodes
    # that it's connecting
    
    l.tag = "Relationship-" + l.source.tag.to_s + "-" + l.destination.tag.to_s
    
    # Now generate the hash for the link
    
    $line_list << {:identifier => l.tag, :nodes => ["Node-" + l.source.tag, "Node-" + l.destination.tag]}
  end

end

# We're all done; prepare the final output and print it as JSON

json_rep = {:nodes => $shape_list, :links => $line_list}
puts JSON.pretty_generate json_rep