# frozen_string_literal: true

require 'bundler/setup'
require 'dotenv'
require 'togglv8'
require 'google_drive'

ROOT_DIR_NAME = 'toggl_log'

def load_env
  Dotenv.load(File.join(__dir__, '.env'))
end

def verify_dir(parent, dir_name)
  dirs = parent.files(q: ['name = ?', dir_name])
  dir = nil
  if dirs.empty?
    puts "#{File.join(parent.title, dir_name)} is not found. Create it."
    dir = parent.create_subcollection(dir_name)
  else
    dir = dirs[0]
  end

  dir
end

load_env

target_date = Date.today

puts "target date:#{target_date.strftime('%Y.%m.%d')}"

toggl = TogglV8::API.new(ENV['TOGGL_TOKEN'])
time_entries = toggl.get_time_entries(start_date: DateTime.now - 30,
                                      end_date: DateTime.now + 30)

# puts time_entries

session = GoogleDrive::Session.from_config('config.json')

root = session.root_collection
toggl_log_dir = verify_dir(root, ROOT_DIR_NAME)

# puts toggl_log_dir.inspect

year_dir_name = target_date.strftime("%Y_#{ROOT_DIR_NAME}")
year_dir = verify_dir(toggl_log_dir, year_dir_name)

target_file_name = target_date.strftime("%Y%m%d_#{ROOT_DIR_NAME}")
target_file = year_dir.file_by_title(target_file_name)

target_file ||= year_dir.create_spreadsheet(target_file_name)
worksheet = target_file.worksheets[0]
puts worksheet[1, 1]
worksheet[1, 1] = 'A'
worksheet.save
