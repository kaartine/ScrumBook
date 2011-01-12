require './helpfunctions.rb'

class Project

  attr_accessor :name, :sprint, :sprintlength, :members, :tasks, :not_saved, :fileName

  def initialize
    @fileName = ""
    @sprintlength = 10
    @not_saved = true

    @tasks = Hash.new
    @sprint = 0
    @sprintHours = Hash.new
  end

  def saved?
    !@not_saved
  end

  def getActiveSprintsTasks
    @tasks[@sprint]
  end

  def addNewTaskToSprint(newTask)
    if newTask.name.size == 0
      raise ArgumentError, "Name is not set"
    end

    logger "before: " + @tasks.inspect, 4
    if !@tasks.has_key?(@sprint)
      @tasks[@sprint] = Array.new
    end

    if @tasks[@sprint].index(newTask.name).nil?
      @tasks[@sprint].push(newTask)
      @not_saved = true
    end
  end

  def getSprintHours(sprint=nil)
    index = @sprint
    if !sprint.nil?
      index = sprint
    end
    if @sprintHours[index].nil?
      return 0
    end
    @sprintHours[index]
  end

  def setSprintHours( hours, sprint=nil )
    index = @sprint
    if !sprint.nil?
      index = sprint
    end
    @sprintHours[index] = hours
  end

  def deleteTask(task)
    @tasks[@sprint].delete(task) unless @tasks[@sprint].nil?
  end

  def moveTaskUp(name)
    id1 = @tasks[@sprint].index(name)
    if id1 == 0 || @tasks[@sprint].size-1 <= 1
      return
    end
    @tasks[@sprint][id1-1], @tasks[@sprint][id1] = @tasks[@sprint][id1], @tasks[@sprint][id1-1]
  end

  def moveTaskDown(name)
    id1 = @tasks[@sprint].index(name)
    if id1 == @tasks[@sprint].size-1 || @tasks[@sprint].size-1 <= 1
      return
    end
    @tasks[@sprint][id1], @tasks[@sprint][id1+1] = @tasks[@sprint][id1+1], @tasks[@sprint][id1]
  end

end


class Task
  attr_accessor :committer, :status, :name
  attr_reader :duration

  def initialize( name, committer, status )
    @name = name.strip
    @committer = committer.strip
    @status = status.strip
    @duration = Array.new
    @duration.push("")
  end

  def name=(n)
    @name = n.strip
  end

  def committer=(c)
    @committer = c.strip
  end

  def status=(s)
    @status = s.strip
  end

  def addDuration(i, value)
    if Integer(value) && value >= 0
      @duration[i] = value
    elsif value.size > 0
      raise ArgumentError, "Duration should be positive integer or zero"
    end
  end

  def ==(id)
    self.name == id
  end

end
