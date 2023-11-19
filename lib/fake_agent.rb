# frozen_string_literal: true

class FakeAgent
  USER_AGENTS = [
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Safari/605.1.15'
  ]

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
        @agents = USER_AGENTS
      end
      @agents.sample
    end
  end
end
