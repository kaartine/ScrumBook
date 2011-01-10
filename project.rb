require './helpfunctions.rb'

class Project

	attr_accessor :name, :sprint, :sprintlength, :members, :tasks, :not_saved

	def initialize
		@sprintlength = 10
		@not_saved = false

		@tasks = Array.new

		@tasks[0] = Array.new
		@tasks[0] << Task.new("scrumbook 0", "JK", "not started")
		@tasks[0] << Task.new("dcc 0", "GK", "in progress")

		@tasks << Array.new
		@tasks[1] << Task.new("scrumbook 1", "JK", "not started")
		@tasks[1] << Task.new("dcc 1", "GK", "in progress")

		logger @tasks.to_s
	end

	def saved?
		@not_saved
	end

	def getActiveSprintsTasks
		@tasks[@sprint]
	end

end


class Task
	attr_accessor :committer, :status, :duration, :name

	def initialize( name, committer, status )
		@name = name
		@committer = committer
		@status = status
		@duration = Array.new
		@duration.push(0)
	end

	def ==(id)
		self.name == id
	end

end