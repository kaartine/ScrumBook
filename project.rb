# Copyright (C) 2011 by Jukka Kaartinen

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.


require './helpfunctions.rb'

class Project

  attr_accessor :name, :sprint, :sprintlength, :members, :tasks, :not_saved, :fileName

  attr_reader :sprintHours

  def initialize
    @fileName = ""
    @sprintlength = 10
    @not_saved = true

    @tasks = Hash.new
    @sprint = 0
    @sprintHours = Hash.new
  end

  def clear
    @fileName = ""
    @sprintlength = 10
    @not_saved = true

    @tasks = Hash.new
    @sprint = 0
    @sprintHours = Hash.new
  end

  def update(project)
    @fileName = project.fileName
    @sprintlength = project.sprintlength
    @not_saved = project.not_saved

    @tasks = project.tasks
    @sprint = project.sprint
    @sprintHours = project.sprintHours
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
    @not_saved = true
    @sprintHours[index] = hours
  end

  def deleteTask(task)
    @not_saved = true
    @tasks[@sprint].delete(task) unless @tasks[@sprint].nil?
  end

  def moveTaskUp(name)
    id1 = @tasks[@sprint].index(name)
    if id1 == 0 || @tasks[@sprint].size-1 <= 1
      return
    end
    @not_saved = true
    @tasks[@sprint][id1-1], @tasks[@sprint][id1] = @tasks[@sprint][id1], @tasks[@sprint][id1-1]
  end

  def moveTaskDown(name)
    id1 = @tasks[@sprint].index(name)
    if id1 == @tasks[@sprint].size-1 || @tasks[@sprint].size-1 <= 1
      return
    end
    @not_saved = true
    @tasks[@sprint][id1], @tasks[@sprint][id1+1] = @tasks[@sprint][id1+1], @tasks[@sprint][id1]
  end

end


class Task
  attr_accessor :committer, :status, :name, :project
  attr_reader :duration

  def initialize( name, committer, status, project = nil )
    @name = name.strip
    @committer = committer.strip
    @status = status.strip
    @duration = Array.new
    @duration.push("")
    @project = project
  end

  def name=(n)
    @project.not_saved = true unless @project.nil?
    @name = n.strip
  end

  def committer=(c)
    @project.not_saved = true unless @project.nil?
    logger "update commiter: " + @project.not_saved.to_s
    @committer = c.strip
  end

  def status=(s)
    @project.not_saved = true unless @project.nil?
    @status = s.strip
  end

  def addDuration(i, value)
    if Integer(value) && value >= 0
      @project.not_saved = true unless @project.nil?
      @duration[i] = value
    elsif value.size > 0
      raise ArgumentError, "Duration should be positive integer or zero"
    end
  end

  def ==(id)
    self.name == id
  end

end
