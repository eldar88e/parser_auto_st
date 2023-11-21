# frozen_string_literal: true

class FakeAgent
  def any
    FakeAgentInternal.instance.get
  end

  private

  class FakeAgentInternal
    include Singleton

    def get
      if @agents.nil?
        #@agents = UserAgent.where(device_type: 'Desktop User Agents').pluck(:user_agent)
        #Hamster.close_connection(UserAgent)
        @agents = YAML.load_file('user-agents.yml')['user_agents']
      end
      @agents.sample
    end
  end
end
