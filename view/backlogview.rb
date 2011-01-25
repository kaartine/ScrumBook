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

require 'tk'
require 'tkextlib/tile'


class BacklogView < Tk::Tile::Frame

  def backlog_update_task(item_id)
    logger "backlog_update_task: " + item_id.to_s
    task = @project.find_backlog_task(item_id)

    if !task.nil?
      task.name = @backlog_task_name.value
      task.milestone = @backlog_task_milestone.value
      task.comment = @backlog_task_comment.value
      task.estimate = @backlog_task_estimate.value
      task.targetted_sprint = @backlog_task_targetted_sprint.value.to_i
    end
  end

  def refresh_backlog(selected_item = nil)
    items = @backlog_tree.children('')
    @backlog_tree.delete(items)

    backlog_fill_tasks(@project.backlog, nil)

    logger "selected_item: #{selected_item}"
    begin
      @backlog_tree.focus_item(selected_item) unless selected_item.nil?
    rescue RuntimeError
    end

    logger "project: " + @project.inspect, 4
  end

  def backlog_fill_tasks(tasks, parent)
    tasks.each do |t|
      logger "add task id: #{t.task_id}", 4
      root = ''
      root = parent.task_id unless parent.nil?
      temp = @backlog_tree.insert(root, 'end', :id => t.task_id, :text => t.name, :tags => ['clickapple'])
      @backlog_tree.set( t.task_id, 'estimate', t.estimate)
      @backlog_tree.set( t.task_id, 'milestone', t.milestone)
      @backlog_tree.set( t.task_id, 'sprint', t.targetted_sprint)
      @backlog_tree.itemconfigure(t.task_id, 'open', true)

      @backlog_tree.tag_bind('clickapple', 'ButtonRelease-1', @change_backlog_task)
    end
  end

  def backlog_refresh_task_editor
    item = @backlog_tree.focus_item()
    logger "selected: " + item.inspect
    if !item.nil?
      task = @project.find_backlog_task(item.to_i)

      logger task.inspect, 4

      @backlog_task_name.value = task.name
      @backlog_task_comment.value = task.comment
      @backlog_task_milestone.value = task.milestone
      @backlog_task_estimate.value = task.estimate
      @backlog_task_targetted_sprint.value = task.targetted_sprint

    else
      @backlog_task_name.value = ''
      @backlog_task_comment.value = ''
      @backlog_task_milestone.value = ''
      @backlog_task_estimate.value = ''
      @backlog_task_targetted_sprint.value = ''
    end
  end


  def initialize(guiManager, tab)
    super(tab) {padding "3 3 12 12"}
    grid(:sticky => 'nws')

    TkGrid.columnconfigure( self, 0, :weight => 1 )
    TkGrid.rowconfigure( self, 0, :weight => 1 )

    @project = Project.create
    @gui = guiManager
    # Backlog tree
    @backlog_tree = Tk::Tile::Treeview.new(self)

    columns = 'estimate milestone sprint'

    @backlog_tree['columns'] = columns.to_s

    @backlog_tree.column_configure( '#0', :width => 400, :anchor => 'center')
    @backlog_tree.heading_configure( 'estimate', :text => ESTIMATE)
    @backlog_tree.column_configure( 'estimate', :width => 60, :anchor => 'center')
    @backlog_tree.heading_configure( 'milestone', :text => MILESTONE)
    @backlog_tree.column_configure( 'milestone', :width => 60, :anchor => 'center')
    @backlog_tree.heading_configure( 'sprint', :text => TARGETTED_SPRINT)
    @backlog_tree.column_configure( 'sprint', :width => 60, :anchor => 'center')

    @change_backlog_task = Proc.new {
      backlog_refresh_task_editor
    }

    $proc_update_backlog_item = Proc.new {
      item = @backlog_tree.focus_item()
      logger "proc_update_backlog_item: " + item.inspect

      unless item.nil?
        task = @project.find_backlog_task(item.to_i)
        backlog_update_task(@backlog_tree.focus_item().to_i)
        refreshView(task.task_id)
      end
    }

    $proc_add_new_backlog_item = Proc.new {
      logger "proc_add_new_backlog_item: " + @backlog_task_name.inspect
      task = Task.new(@backlog_task_name.value, '', NEW_STATUS)
      task.milestone = @backlog_task_milestone.value
      task.estimate = @backlog_task_estimate.value
      task.comment = @backlog_task_comment.value
      task.targetted_sprint = @backlog_task_targetted_sprint.value.to_i
      begin
        @project.add_new_task_to_backlog(task)
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

    $proc_backlog_delete_task = Proc.new {
      item = @backlog_tree.focus_item()
      logger "proc_backlog_delete_task: " + item.inspect
      if !item.nil?
        @project.delete_backlog_task(item.to_i)
      end
      refreshView
    }

    $proc_backlog_move_task_up = Proc.new { }
    $proc_backlog_move_task_down = Proc.new { }
    $proc_backlog_copy_tasks_to_sprint = Proc.new { }


    # Task update button
    backlog_updateButton = TkButton.new(self) {
      text 'Update Task'
      underline 0
      command( $proc_update_backlog_item )
    }

    # Task update button
    backlog_moveUpButton = TkButton.new(self) {
      text 'Move Up'
      command( $proc_backlog_move_task_up)
    }

    # Task update button
    backlog_moveDownButton = TkButton.new(self) {
      text 'Move Down'
      command( $proc_backlog_move_task_down )
    }

    # Add new task button
    backlog_addNewTaskButton = TkButton.new(self) {
      text 'Add new Task'
      underline 8
      command( $proc_add_new_backlog_item )
    }

    # Delete selected task button
    backlog_deleteButton = TkButton.new(self) {
      text 'Delete Task'
      underline 0
      command( $proc_backlog_delete_task )
    }

    # Copy selected tasks to sprint button
    backlog_copy_button = TkButton.new(self) {
      text COPY_TO_SPRINT
      underline 0
      command( $proc_backlog_copy_tasks_to_sprint )
    }


    # Task edition fields
    @backlog_task_name = TkVariable.new
    @backlog_task_milestone = TkVariable.new
    @backlog_task_estimate = TkVariable.new
    @backlog_task_targetted_sprint = TkVariable.new

    task_name_entry = TkEntry.new(self)
    task_name_entry.textvariable = @backlog_task_name

    task_milestone_entry = TkEntry.new(self)
    task_milestone_entry.textvariable = @backlog_task_milestone

    task_estimate_entry = TkEntry.new(self)
    task_estimate_entry.textvariable = @backlog_task_estimate

    task_targetted_sprint_entry = TkEntry.new(self)
    task_targetted_sprint_entry.textvariable = @backlog_task_targetted_sprint

    @backlog_task_comment = TkText.new(self) {
      width 30
      height 5
      borderwidth 1
    }

    @backlog_tree.grid(        :row => 0, :column => 0, :columnspan => 4, :rowspan => 10, :sticky => 'news' )

    backlog_copy_button.grid(              :row => 1, :column => 7, :sticky => 'new' )

    TkGrid(TkLabel.new(self, :text => TASK_NAME), :row => 20, :column => 0)
    task_name_entry.grid(                                 :row => 21, :column => 0, :sticky => 'news' )
    TkGrid(TkLabel.new(self, :text => ESTIMATE), :row => 20, :column => 1)
    task_estimate_entry.grid(                             :row => 21, :column => 1, :sticky => 'news' )
    TkGrid(TkLabel.new(self, :text => MILESTONE), :row => 20, :column => 2)
    task_milestone_entry.grid(                            :row => 21, :column => 2, :sticky => 'news' )
    TkGrid(TkLabel.new(self, :text => TARGETTED_SPRINT), :row => 20, :column => 3)
    task_targetted_sprint_entry.grid(                     :row => 21, :column => 3, :sticky => 'news' )

    backlog_updateButton.grid(           :row => 21, :column => 5, :sticky => 'nw' )
    backlog_moveUpButton.grid(           :row => 21, :column => 7, :sticky => 'nw' )
    backlog_moveDownButton.grid(         :row => 22, :column => 7, :sticky => 'nw' )
    TkGrid(TkLabel.new(self, :text => " "), :row => 23, :column => 5 + 1)
    backlog_deleteButton.grid(           :row => 24, :column => 5, :sticky => 'nw' )
    backlog_addNewTaskButton.grid(       :row => 22, :column => 5, :sticky => 'nw' )

    TkGrid(TkLabel.new(self, :text => COMMENT), :row => 23, :column => 0)
    @backlog_task_comment.grid(           :row => 24, :column => 0, :columnspan => 2, :sticky => 'news')

    self
  end

  def bind_shortcuts(root)
    logger "bind_shortcuts"
    root.bind( "Control-u", $proc_update_backlog_item )
    root.bind( "Control-t", $proc_add_new_backlog_item )
    root.bind( "Control-b", proc {} )
    root.bind( "Control-d", $proc_backlog_delete_task )
  end

  def refreshView(selected_item = nil?)
    refresh_backlog(selected_item)
    backlog_refresh_task_editor

    @gui.refreshTitle
  end

  def update_project
    @project = Project.create
  end


end