# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  # Every User has organizer + attendee capacities by default — no role assignment needed.
  # Only admin? is a boolean flag on User (set via Story 4.6 UI). Policies express this:
  #   user.present?  → has organizer/attendee capacity
  #   user.admin?    → has admin capacity
  def initialize(user, record)
    @user = user
    @record = record
  end

  # Default: deny everything. Subclass policies opt in explicitly per resource.
  def index? = false
  def show? = false
  def create? = false
  def new? = false
  def update? = false
  def edit? = false
  def destroy? = false

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    # Forces subclass to implement — catches misconfigured policies at development time
    # rather than silently returning empty scope in production.
    def resolve
      raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end

    private

    attr_reader :user, :scope
  end
end
