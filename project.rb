class Project

	attr_accessor :name, :sprintlength, :members, :tasks
	@name
	@sprintlength
	@members = []
	@tasks

	@not_saved = false

	def saved?
		@not_saved
	end

	def save
		print "TODO: save function"
	end
end