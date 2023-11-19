# frozen_string_literal: true

# RunId(active_record_model: RunsModel )
# Description:
#   - Class for work with *_runs table.
#   - Connect class by active_record_model to *_runs table.
#   – Get new run_id by making new row or using last not finished row
# Sample:
#   run_id_class = RunId(active_record_model: CourtRuns)
#   current_run_id = run_id_class.run_id
#   ...
#   run_id_class.finish

class RunId
  attr_reader :run_id

  def initialize(model)
    @db_model = model
    @run_id   = last_id
  end

  def last_id
    last = last_run
    last && last.status != 'finish' ? last.id : set_new_id
  end

  def update_id
    @run_id = last_id
  end

  def status
    last_run.status
  end

  def status=(new_status)
    last_run.update status: new_status.to_s
    new_status.to_s
  end

  def finish
    @db_model.find_by(id: @run_id).update status: 'finish'
    Hamster.close_connection(@db_model)
  end

  private

  def last_run
    res = @db_model.last
    Hamster.close_connection(@db_model)
    res
  end

  def set_new_id
    res = @db_model.create.id
    Hamster.close_connection(@db_model)
    res
  end
end
