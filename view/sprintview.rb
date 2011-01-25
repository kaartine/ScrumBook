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

class SprintView < Tk::Tile::Frame

  def updateTask(item_id)
    logger "updateTask: " + item_id.to_s
    task = @project.findTask(item_id)

    if !task.nil?
      task.name = @taskName.value
      task.committer = @taskCommitter.value
      task.status = @taskStatus.value
      task.comment = @task_comment.value
      logger "comment: #{@task_comment.value}"
      logger "task.comment: #{task.comment}"
      @project.sprintlength.times.each  do |i|
        task.addDuration(i, @taskDuration[i].value.to_i)
        logger "task update w#{i}: " + task.duration[i].to_s
      end
    end
  end

  def refreshSprint(selected_item = nil)
    @project.sprint = @projectSprint.value

    id = @projectSprint.value.to_i
    logger "sprint_id: " + id.to_s
    @project.sprint = id

    items = @sprintTaskTree.children('')
    @sprintTaskTree.delete(items)

    @effortsRemaining.clear

    fillTasks(@project.tasks[id], nil)

    @project.sprintlength.times.each do |i|
      @effortsRemainingLabel[i].text = @effortsRemaining[i]
    end

    logger "selected_item: #{selected_item}"
    begin
      @sprintTaskTree.focus_item(selected_item) unless selected_item.nil?
    rescue RuntimeError
    end

    logger "project: " + @project.inspect, 4
  end

  def fillTasks(tasks, parent)
    if tasks
      tasks.each do |t|
        logger "add task id: #{t.task_id}", 4
        root = ''
        root = parent.task_id unless parent.nil?
        temp = @sprintTaskTree.insert(root, 'end', :id => t.task_id, :text => t.name, :tags => ['clickapple'])
        @sprintTaskTree.set( t.task_id, 'committer', t.committer)
        @sprintTaskTree.set( t.task_id, 'status', t.status)
        @sprintTaskTree.itemconfigure(t.task_id, 'open', true)

        @project.sprintlength.times.each do |i|
          @sprintTaskTree.set(t.task_id, "w#{i}", t.duration[i])
          @effortsRemaining.push(0) if @effortsRemaining[i].nil?
          @effortsRemaining[i] += t.duration[i]
        end

        @sprintTaskTree.tag_bind('clickapple', 'ButtonRelease-1', @changeTask)
        logger "t.tasks: #{t.tasks.inspect}", 4
        fillTasks(t.tasks, t)
      end
    end
  end

  def refreshTaskEditor
    item = @sprintTaskTree.focus_item()
    logger "selected: " + item.inspect
    if !item.nil?
      task = @project.findTask(item.to_i)

      logger task.inspect, 4

      @taskName.value = task.name
      @taskCommitter.value = task.committer
      @taskStatus.value = task.status
      @task_comment.value = task.comment
      @project.sprintlength.times.each  do |i|
        @taskDuration[i].value = task.duration[i]
      end
    else
      @taskName.value = ''
      @taskCommitter.value = ''
      @taskStatus.value = ''
      @task_comment.value = ''
      @project.sprintlength.times.each  do |i|
        @taskDuration[i].value = ''
      end
    end
  end

  def initialize(guiManager, tab)
    super(tab) {padding "3 3 12 12"}
    grid(:sticky => 'nws')

    TkGrid.columnconfigure( self, 0, :weight => 1 )
    TkGrid.rowconfigure( self, 0, :weight => 1 )

    create_procs

    @gui = guiManager
    @project = Project.create

    @effortsRemainingLabel = Array.new
    @effortsRemaining = Array.new

    #sprint selector
    sprintEntry = TkSpinbox.new(self) {
      to 800
      from 0
      increment 1
      width 10
    }
    sprintEntry.bind("ButtonRelease-1", @changeSprint)
    sprintEntry.bind("KeyRelease-Up", @changeSprint)
    sprintEntry.bind("KeyRelease-Down", @changeSprint)

    @projectSprint = TkVariable.new
    @projectSprint.value = 0
    sprintEntry.textvariable = @projectSprint

    # Hours availble for current sprint
    @hoursAvailableVar = TkVariable.new
    hoursAvailable = TkEntry.new(self) {width 5}
    hoursAvailable.textvariable = @hoursAvailableVar

    # Sprint's task tree
    @sprintTaskTree = Tk::Tile::Treeview.new(self)

    columns = 'committer status'
    @project.sprintlength.times.each do |d|
      columns += " w#{d}"
    end

    @sprintTaskTree['columns'] = columns.to_s
    logger @sprintTaskTree['columns'], 4

    @sprintTaskTree.column_configure( 'committer', :width => 70, :anchor => 'center')
    @sprintTaskTree.heading_configure( 'committer', :text => 'Committer')
    @sprintTaskTree.heading_configure( 'status', :text => 'Status')

    @project.sprintlength.times.each do |d|
      @sprintTaskTree.heading_configure( "w#{d}", :text => DAYS[selectDay(d)])
      @sprintTaskTree.column_configure( "w#{d}", :width => 10, :anchor => 'center')
    end

    # Task edition fields
    @taskName = TkVariable.new
    @taskCommitter = TkVariable.new
    @taskStatus = TkVariable.new
    @taskDuration = Array.new
    @project.sprintlength.times.each  do |i|
      @taskDuration.push(TkVariable.new)
    end

    taskNameEntry = TkEntry.new(self) {width 33}
    taskNameEntry.textvariable = @taskName

    taskCommitter = TkEntry.new(self) #{width 10} #Tk::Tile::ComboBox.new(self)
    taskCommitter.textvariable = @taskCommitter

    taskStatus = TkEntry.new(self) #{width 15} #Tk::Tile::ComboBox.new(self)
    taskStatus.textvariable = @taskStatus

    taskDurationEntry = Array.new
    @project.sprintlength.times.each do |i|
      taskDurationEntry.push(TkEntry.new(self) do
        width 3
      end)
      taskDurationEntry[i].textvariable = @taskDuration[i]
    end

    $proc_sprint_add_new_sub_task = Proc.new {
      task = Task.new(@taskName.value, @taskCommitter.value, @taskStatus.value)
      task.comment = @task_comment.value
      @project.sprintlength.times.each  do |i|
        task.addDuration(i, @taskDuration[i].value.to_i)
        logger "task update w#{i}: " + task.duration[i].to_s
      end
      begin
        parent_id = @sprintTaskTree.focus_item().to_i
        @project.addNewTaskToSprint(task, parent_id)
      rescue ArgumentError
        Tk.messageBox(
            'type'    => "ok",
            'icon'    => "info",
            'title'   => "Title",
            'message' => "You have to give name to your task!"
          )
      end
      refreshView
    }

    $proc_sprint_update_task = Proc.new {
      item = @sprintTaskTree.focus_item()
      logger "procUpdateTask: " + item.inspect

      unless item.nil?
        task = @project.findTask(item.to_i)
        updateTask(@sprintTaskTree.focus_item().to_i)
        refreshView(task.task_id)
      end
    }

    $proc_sprint_delete_task = Proc.new {
      item = @sprintTaskTree.focus_item()
      logger "procUpdateTask: " + item.inspect
      if !item.nil?
        @project.deleteTask(item.to_i)
      end
      refreshView
    }

    $proc_sprint_add_new_task = Proc.new {
      logger "procAddNewTask: " + @taskName.inspect
      task = Task.new(@taskName.value, @taskCommitter.value, @taskStatus.value)
      @project.sprintlength.times.each  do |i|
        task.addDuration(i, @taskDuration[i].value.to_i)
        logger "task update w#{i}: " + task.duration[i].to_s
      end
      begin
        @project.addNewTaskToSprint(task)
      rescue ArgumentError
        Tk.messageBox(
            'type'    => "ok",
            'icon'    => "info",
            'title'   => "Title",
            'message' => "You have to give name to your task!"
          )
      end
      refreshView
    }

    $proc_sprint_move_task_up = Proc.new {
      item = @sprintTaskTree.focus_item()
      logger "procMoveTaskUp: " + item.inspect
      if !item.nil?
        @project.moveTaskUp(item.to_i)
      end
      refreshView(item)
    }

    $proc_move_task_down = Proc.new {
      item = @sprintTaskTree.focus_item()
      logger "procMoveTaskDown: " + item.inspect
      if !item.nil?
        @project.moveTaskDown(item.to_i)
      end
      refreshView(item)
    }


    # Task update button
    copyButton = TkButton.new(self) {
      text 'Copy open tasks'
      command( $proc_sprint_update_task )
    }

    # Task update button
    updateButton = TkButton.new(self) {
      text 'Update Task'
      underline 0
      command( $proc_sprint_update_task )
    }

    # Task update button
    moveUpButton = TkButton.new(self) {
      text 'Move Up'
      command( $proc_sprint_move_task_up)
    }

    # Task update button
    moveDownButton = TkButton.new(self) {
      text 'Move Down'
      command( $proc_move_task_down )
    }

    # Add new task button
    addNewTaskButton = TkButton.new(self) {
      text 'Add new Task'
      underline 8
      command( $proc_sprint_add_new_task )
    }

    addNewSubTaskButton = TkButton.new(self) {
      text 'Add Sub Task'
      underline 6
      command( $proc_sprint_add_new_sub_task )
    }

    # Delete selected task button
    deleteButton = TkButton.new(self) {
      text 'Delete Task'
      underline 0
      command( $proc_sprint_delete_task )
    }

    @task_comment = TkText.new(self) {
      width 30
      height 5
      borderwidth 1
    #  font TkFont.new('times 12 bold')
    }

    @sprintTaskTree.grid(        :row => 0, :column => 0, :columnspan => numOfColumns, :rowspan => 10, :sticky => 'news' )
    TkGrid(TkLabel.new(self, :text => "Select your sprint:"), :row => 1, :column => numOfColumns + 2, :sticky => 'ne')
    sprintEntry.grid(            :row => 1, :column => numOfColumns + 3, :columnspan => 2,:sticky => 'nw' )
    TkGrid(TkLabel.new(self, :text => " "), :row => 1, :column => numOfColumns + 1)
    TkGrid(TkLabel.new(self, :text => " "), :row => 0, :column => numOfColumns + 3)
    TkGrid(TkLabel.new(self, :text => "Team velocity:"), :row => 2, :column => numOfColumns + 2, :sticky => 'ne')
    hoursAvailable.grid(         :row => 2, :column => numOfColumns + 3, :columnspan => 2, :sticky => 'nw' )
    copyButton.grid(             :row => 4, :column => numOfColumns + 2, :sticky => 'ne' )

    TkGrid(TkLabel.new(self, :text => "Task name"), :row => 20, :column => 0)
    taskNameEntry.grid(                                   :row => 21, :column => 0, :sticky => 'news' )
    TkGrid(TkLabel.new(self, :text => "Committer"), :row => 20, :column => 1)
    taskCommitter.grid(                                   :row => 21, :column => 1, :sticky => 'news' )
    TkGrid(TkLabel.new(self, :text => "Status"),    :row => 20, :column => 2)
    taskStatus.grid(                                      :row => 21, :column => 2, :sticky => 'news' )

    TkGrid(TkLabel.new(self, :text => 'Remaingin effort:') do font TkFont.new('Arial 12 bold') end,  :row => 11, :column => 2)
    @project.sprintlength.times.each do |i|
      @effortsRemainingLabel.push(TkLabel.new(self, :text => '0', :width => '3') do font TkFont.new('Arial 10 bold') end)
      TkGrid(@effortsRemainingLabel[i],  :row => 11, :column => 3+i)
    end

    TkGrid(TkLabel.new(self, :text => " "), :row => 12, :column => numOfColumns + 1)

    @project.sprintlength.times.each do |i|
      TkGrid(TkLabel.new(self, :text => DAYS[selectDay(i)]),  :row => 20, :column => 3+i)
    end
    @project.sprintlength.times.each do |i|
      taskDurationEntry[i].grid(                          :row => 21, :column => 3+i, :sticky => 'news' )
    end

    updateButton.grid(           :row => 21, :column => numOfColumns + 2, :sticky => 'nw' )
    moveUpButton.grid(           :row => 21, :column => numOfColumns + 4, :sticky => 'nw' )
    moveDownButton.grid(         :row => 22, :column => numOfColumns + 4, :sticky => 'nw' )
    TkGrid(TkLabel.new(self, :text => " "), :row => 23, :column => numOfColumns + 1)
    deleteButton.grid(           :row => 24, :column => numOfColumns + 4, :sticky => 'nw' )
    addNewTaskButton.grid(       :row => 22, :column => numOfColumns + 2, :sticky => 'nw' )
    addNewSubTaskButton.grid(    :row => 23, :column => numOfColumns + 2, :sticky => 'nw' )

    TkGrid(TkLabel.new(self, :text => COMMENT), :row => 23, :column => 0)
    @task_comment.grid(           :row => 24, :column => 0, :columnspan => 4, :sticky => 'news')

    @sprintTaskTree.bind("KeyRelease-Up", @changeTask)
    @sprintTaskTree.bind("KeyRelease-Down", @changeTask)
  end

  def create_procs
    @changeSprint = Proc.new {
      refreshView
    }

    @changeTask = Proc.new {
      refreshTaskEditor
    }
  end

  def refreshView(selected_item = nil?)
    refreshSprint(selected_item)
    refreshTaskEditor

    @gui.refreshTitle
  end

  def update_project
    @project = Project.create
  end

  def bind_shortcuts(root)
    root.bind( "Control-u", $proc_sprint_update_task )
    root.bind( "Control-t", $proc_sprint_add_new_task )
    root.bind( "Control-b", $proc_sprint_add_new_sub_task )
    root.bind( "Control-d", $proc_sprint_delete_task )
  end

end