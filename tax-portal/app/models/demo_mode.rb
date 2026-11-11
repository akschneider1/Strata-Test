# frozen_string_literal: true

# Demo-only conveniences: one-click sign-in as a made-up person, in the
# visitor's own copy of the demo (DemoSpace). Off unless DEMO_MODE=true, and
# never available in production.
module DemoMode
  COOKIE = :demo_space
  Person = Struct.new(:key, :name, :role) do
    def first_name = name.split.first
  end

  def self.enabled?
    !Rails.env.production? && ENV["DEMO_MODE"] == "true"
  end

  # The demo people, in the order the demo guide tells the story. The home
  # page lists them from here, so it needs nothing in the database.
  def self.roster
    taxpayers = %i[maya daniela walter elena jordan].map { |key| Person.new(key.to_s, DemoData::PEOPLE.fetch(key)[:name].join(" "), "taxpayer") }
    taxpayers + DemoData::EXAMINERS.map { |key, name| Person.new(key.to_s, name, "examiner") }
  end

  # The visitor's copy of the demo, if they have one that is still in use.
  # Looking it up counts as using it. A copy left idle is discarded.
  def self.space_for(cookies)
    space = DemoSpace.find_by(id: cookies.signed[COOKIE])
    return nil unless space

    if space.idle?
      space.discard!
      nil
    else
      space.tap(&:used!)
    end
  end

  # Whether the tax engine has loaded its rules. A new copy of the demo files
  # a few returns, which needs it.
  # Once it is ready it stays ready, so the answer is remembered and the
  # home page doesn't ask the engine on every visit.
  def self.ready?
    @ready ||= TaxEngine.client(timeout: 3).status&.fetch("ready", false) == true
  rescue TaxEngine::Error
    false
  end

  # The returns a signed-in person may see across taxpayers: those in the
  # same copy of the demo. People who aren't demo people (no copy) see only
  # returns that belong to no copy.
  def self.cases_for(user)
    people = User.where(demo_space_id: user.demo_space_id)
    TaxReturnCase.where(application_form_id: TaxReturn.where(user_id: people.select(:id)).select(:id))
  end

  def self.case_ids_for(user)
    cases_for(user).unscope(:includes).select(:id)
  end

  def self.tasks_for(user)
    Strata::Task.where(case_id: case_ids_for(user))
  end
end
