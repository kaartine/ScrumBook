require './helpfunctions.rb'

class Project

  attr_accessor :name, :sprint, :sprintlength, :members, :tasks, :not_saved, :fileName

  def initialize
    @fileName = ""
    @sprintlength = 10
    @not_saved = false

    @tasks = Hash.new

#    @tasks[0] = Array.new
#    @tasks[0] << Task.new("scrumbook 0", "JK", "not started")
#    @tasks[0] << Task.new("dcc 0", "GK", "in progress")

#    @tasks << Array.new
#    @tasks[1] << Task.new("scrumbook 1", "JK", "not started")
#    @tasks[1] << Task.new("dcc 1", "GK", "in progress")
  end

  def saved?
    @not_saved
  end

  def getActiveSprintsTasks
    @tasks[@sprint]
  end

  def addNewTaskToSprint(newTask)
    logger "before: " + @tasks.inspect
    if !@tasks.has_key?(@sprint)
      @tasks[@sprint] = Array.new
    end

    if @tasks[@sprint].index(newTask.name).nil?
      @tasks[@sprint].push(newTask)
    else
      nil
    end

  end

end


class Task
  attr_accessor :committer, :status, :duration, :name

  def initialize( name, committer, status )
    @name = name
    @committer = committer
    @status = status
    @duration = Array.new
    @duration.push("")
  end

  def ==(id)
    self.name == id
  end

end
