# frozen_string_literal: true

require 'bundler/setup'
require 'dotenv'
require 'togglv8'
require 'google_drive'
require 'time'

ROOT_DIR_NAME = 'toggl_log'
INVALID_TIME = Time.new(1960, 1, 1, 0, 0, 0)

module GoogleDrive
  class Worksheet
    # clear all contents
    def clear_all
      (1..max_cols).each do |col|
        (1..max_rows).each do |row|
          self[row, col] = ''
        end
      end
    end
  end
end

module TogglV8
  class API
    def my_clients_with_id
      res = nil
      a = my_clients
      if a
        res = {}
        a.each do |v|
          res[v['id']] = v
        end
      end

      res
    end

    def projects_with_id(workspace_id)
      res = nil
      projects = projects(workspace_id)
      if projects
        res = {}
        projects.each do |v|
          res[v['id']] = v
        end

      end
      res
    end
  end
end

def load_env
  Dotenv.load
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
workspace_id = toggl.workspaces.first['id']

clients =  toggl.my_clients_with_id
projects = toggl.projects_with_id(workspace_id)

time_entries = toggl.get_time_entries(start_date: DateTime.now - 30,
                                      end_date: DateTime.now + 30)
time_entries.each do |entry|
  entry['start_time'] = if entry['start']
                          Time.parse(entry['start'])
                        else
                          INVALID_TIME
                        end

  entry['stop_time'] = if entry['stop']
                         Time.parse(entry['stop'])
                       else
                         INVALID_TIME
                       end
  project = (projects[entry['pid']] if entry['pid'])
  entry['project'] = (project['name'] if project)
  entry['client'] = if project
                      clients[project['cid']]['name'] if clients[project['cid']]
                    end
end

time_entries.sort do |l, r|
  l['start_time'] <=> r['start_time']
end

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

# clear worksheet data
worksheet.clear_all

ids = %w[id description start stop client project]

row = 1
ids.each_with_index do |v, i|
  worksheet[row, i + 1] = v
end
row += 1

time_entries.each do |entry|
  ids.each_with_index do |v, i|
    worksheet[row, i + 1] = entry[v]
  end
  row += 1
end

# puts worksheet[1, 1]
# worksheet[1, 1] = 'A'
worksheet.save
