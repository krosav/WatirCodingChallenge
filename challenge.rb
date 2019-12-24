require 'watir'
require 'json'

class LinkedinMessageSender

   def initialize
      #Read the json config file
      jsonString = File.read("./config.json")
      @parsedJson = JSON.parse jsonString
      case @parsedJson["browser"]
          when 'chrome'
              @browser = Watir::Browser.new :chrome
          when 'ie'
              @browser = Watir::Browser.new :ie
          else
              @browser = Watir::Browser.new :firefox
      end

      # Go to LinkedIn and maximise the browser if needed 
      @browser.goto('www.linkedin.com')
      @browser.window.maximize
   end

   def clickElement(identifier, selector)
      i = 0
      while (!@browser.element(identifier => selector).exists? && i < 100 )  do
         sleep(0.5)
         i += 1
      end

      if i >= 100 then
          raise "Error waiting for element to click!"
      end
      @browser.element(identifier => selector).click
   end

   def fillInput(identifier, selector, string)
      i = 0 
      while (!@browser.element(identifier => selector).exists? && i < 100 )  do
         sleep(0.5)
         i += 1
      end

      if i >= 100 then
          raise "Error waiting for input to fill!"
      end
      @browser.element(identifier => selector).send_keys(string)
   end

   def Login
      # Click the Sign In button
      clickElement(:class, "nav__button-secondary")

      #Type Username
      fillInput(:id, "username", @parsedJson["username"])

      #Type Password
      fillInput(:id, "password", @parsedJson["password"])

      #Click on Submit
      clickElement(:type, "submit")

      #Wait for the login page to disappear following the login, looking at the Submit button
      i = 0
      while (@browser.element(:type => "submit").exists? && i < 100 )  do
         sleep(0.5)
         i += 1
      end
      if i >= 100 then
          raise "Error waiting for closing of the login page"
      end
   end

   def FindAccount
       # Search for the account we want to send message to
       i = 0
       while (!@browser.input(:class => ["search-global-typeahead__input", "always-show-placeholder"], :type => "text", :role => "combobox").exists? && i < 100) do
           sleep(0.5)
           i += 1
       end
       if i >= 100 then
          raise "Error waiting for searching for the account name!"
       end

       input = @browser.input(:class => ["search-global-typeahead__input", "always-show-placeholder"], :type => "text", :role => "combobox")
       input.send_keys(@parsedJson["account"])
       input.send_keys(:enter)

       # Click on the account name
       i = 0
       while (!@browser.span(:class => ["name", "actor-name"], :text => @parsedJson["account"] ).exists? && i < 100) do
           sleep(0.5)
           i += 1
       end
       if i >= 100 then
          raise "Error waiting for clicking on the account name!"
       end
       @browser.span(:class => ["name", "actor-name"], :text => @parsedJson["account"] ).click
   end

   def SendMessage
       if @parsedJson["reallySendMessage"] then
           #Click the Message button
           i = 0
           while (!@browser.span( :text => /Message/).exists? && i < 100 ) do
               sleep(0.5)
               i += 1
           end
           if i >= 100 then
               raise "Error waiting for the Message button!"
           end

           @browser.span(:text => /Message/).click
 
           #Type the message to send
           fillInput(:class, ["msg-form__contenteditable", "t-14", "t-black--light", "t-normal", "flex-grow-1", "notranslate"], @parsedJson["message"])

           #Click the Send button
           clickElement(:class, ["msg-form__send-button", "artdeco-button", "artdeco-button--1"])
       end
   end

   def Logout
       #Click the Me button
       clickElement(:class, ["nav-item__title", "nav-item__dropdown-trigger--title"])

       #Click on Sign out
       i = 0
       while (!@browser.element( :tag_name => "a", :class => ["block", "ember-view"], :text => /Sign out/).exists? && i < 100 )do
          sleep(0.5)
          i += 1
       end
       if i >= 100 then
          raise "Error waiting for the Sign Out button!"
       end
       @browser.element( :tag_name => "a", :class => ["block", "ember-view"], :text => /Sign out/).click

       # Wait for the Sign Out button to disappear after being clicked
       i = 0
       while (@browser.element( :tag_name => "a", :class => ["block", "ember-view"], :text => /Sign out/).exists? && i < 100 ) do
          sleep(0.5)
          i += 1
       end
       if i >= 100 then
          raise "Error during Sign Out!"
       end
   end

   def BrowserQuit
       @browser.quit
       puts "Browser closed"
   end
end

#Init the object
sender = LinkedinMessageSender.new

# Login to Linkedin
begin
   sender.Login
   puts "Login successful!"
rescue StandardError => e 
   # If here, login failed
   puts "Test failed, login unsuccessful - " + e.message
   sender.BrowserQuit 
   exit(1)
end

# Do the message sending
begin
   sender.FindAccount
   sender.SendMessage
   puts "Test passed - Message sent successfully!"
rescue StandardError => e 
   puts "Test Failed " + e.message
end

# Be sure to logout at the end
begin
   sender.Logout
   puts "Logout successful."
rescue StandardError => e 
   puts "Test failed, sign out unsuccessful - " + e.message
end

#Be sure to quit the browser!
sender.BrowserQuit
