require 'active_support/time'

RSpec.describe Floe::Workflow do
  let(:now)   { Time.now.utc }
  let(:input) { {"input" => "value"}.freeze }

  describe "#new" do
    it "sets initial state" do
      workflow, ctx = make_workflow(input, {"FirstState" => {"Type" => "Succeed"}})

      expect(workflow.status).to eq("pending")
      expect(workflow.end?).to eq(false)

      expect(ctx.status).to eq("pending")
      expect(ctx.started?).to eq(false)
      expect(ctx.running?).to eq(false)
      expect(ctx.ended?).to eq(false)
    end
  end

  describe "#run!" do


    it "sets execution variables for success" do
      workflow, ctx = make_workflow(input, {"FirstState" => {"Type" => "Succeed"}})
      workflow.run!

      # state
      expect(ctx.state["EnteredTime"]).to be_within(1.second).of(now)
      expect(ctx.state["Guid"]).to be
      expect(ctx.state_name).to eq("FirstState")
      expect(ctx.input).to eq(input)
      expect(ctx.output).to eq(input)
      expect(ctx.state["FinishedTime"]).to be_within(1.second).of(now)
      expect(ctx.state["Duration"]).to be <= 1
      expect(ctx.status).to eq("success")

      # execution
      expect(ctx.started?).to eq(true)
      expect(ctx.running?).to eq(false)
      expect(ctx.ended?).to eq(true)

      # final results
      expect(workflow.output).to eq(input)
      expect(workflow.status).to eq("success")
      expect(workflow.end?).to eq(true)
    end

    it "sets execution variables for failure" do
      workflow, ctx = make_workflow(input, {"FirstState" => {"Type" => "Fail", "Cause" => "Bad Stuff", "Error" => "Issue"}})
      workflow.run!

      # state
      expect(ctx.state["EnteredTime"]).to be_within(1.second).of(now)
      expect(ctx.state["Guid"]).to be
      expect(ctx.state_name).to eq("FirstState")
      expect(ctx.input).to eq(input)
      expect(ctx.output).to eq(input)
      expect(ctx.state["FinishedTime"]).to be_within(1.second).of(now)
      expect(ctx.state["Duration"]).to be <= 1
      expect(ctx.state["Cause"]).to eq("Bad Stuff")
      expect(ctx.state["Error"]).to eq("Issue")
      expect(ctx.status).to eq("failure")

      # execution
      expect(ctx.started?).to eq(true)
      expect(ctx.running?).to eq(false)
      expect(ctx.ended?).to eq(true)

      # final results
      expect(workflow.output).to eq(input)
      expect(workflow.status).to eq("failure")
      expect(workflow.end?).to eq(true)
    end
  end

  describe "#step" do
    it "runs a success step" do

      workflow, ctx = make_workflow(input, {"FirstState" => {"Type" => "Succeed"}})

      expect(workflow.status).to eq("pending")
      expect(workflow.end?).to eq(false)
      expect(ctx.status).to eq("pending")
      expect(ctx.started?).to eq(false)
      expect(ctx.running?).to eq(false)
      expect(ctx.ended?).to eq(false)

      workflow.step

      expect(workflow.output).to eq(input)
      expect(workflow.status).to eq("success")
      expect(workflow.end?).to eq(true)
      expect(ctx.output).to eq(input)
      expect(ctx.status).to eq("success")
      expect(ctx.started?).to eq(true)
      expect(ctx.running?).to eq(false)
      expect(ctx.ended?).to eq(true)
    end
  end

  private

  def make_workflow(input, payload, creds: {})
    context = Floe::Workflow::Context.new(:input => input)
    workflow = Floe::Workflow.new(make_payload(payload), context, creds)
    [workflow, context]
  end

  def make_payload(states)
    start_at ||= states.keys.first

    {
      "Comment" => "Sample",
      "StartAt" => start_at,
      "States"  => states
    }
  end
end
