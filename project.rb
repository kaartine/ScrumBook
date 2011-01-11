require './helpfunctions.rb'

class Project

  attr_accessor :name, :sprint, :sprintlength, :members, :tasks, :not_saved, :fileName

  def initialize
    @fileName = ""
    @sprintlength = 10
    @not_saved = true

    @tasks = Hash.new
  end

  def saved?
    !@not_saved
  end

  def getActiveSprintsTasks
    @tasks[@sprint]
  end

  def addNewTaskToSprint(newTask)
    logger "before: " + @tasks.inspect
    if !@tasks.has_key?(@sprint)
      @tasks[@sprint] = Array.new
    end

		if newTask.name.size == 0
			raise ArgumentError, "Name is not set"
		end

    if @tasks[@sprint].index(newTask.name).nil?
      @tasks[@sprint].push(newTask)
      @not_saved = true
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

  def name=(n)
  	name = n.trim
  end


  def ==(id)
    self.name == id
  end

end
