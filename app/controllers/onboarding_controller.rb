# Multi-step onboarding wizard (docs/onboarding-flow.md §3).
#
# "ถัดไป" saves the step and moves on. "ย้อนกลับ" saves the step if it is valid,
# then goes back either way, so earlier answers are never lost.
#
# Each step lives in a concern (Onboarding::ProfileStep, ...) defining private
# `load_<step>_step` (sets up @record for the form) and `save_<step>_step`
# (returns true when saved), plus a partial in onboarding/steps.
class OnboardingController < ApplicationController
  # Steps the user may skip without filling anything in.
  SKIPPABLE_STEPS = %w[ interests ].freeze
  include Onboarding::ProfileStep
  include Onboarding::FinanceStep
  include Onboarding::AddressStep
  include Onboarding::DocumentsStep
  include Onboarding::BankStep
  include Onboarding::InterestsStep
  include Onboarding::ReviewStep

  layout "site"

  before_action :require_pending_onboarding
  before_action :set_step, only: %i[ edit update ]
  before_action :load_step, only: %i[ edit update ]

  def show
    redirect_to onboarding_step_path(Current.user.current_onboarding_step)
  end

  def edit
  end

  def update
    saved =
      if params[:skip] && @step.in?(SKIPPABLE_STEPS) then true
      elsif params[:back] && params[:onboarding].blank? then false
      else run_step_hook(:save, default: true)
      end

    if params[:back]
      redirect_to onboarding_step_path(adjacent_step(-1))
    elsif saved && @step == User::ONBOARDING_STEPS.last
      redirect_to root_path, notice: "ส่งข้อมูลเรียบร้อยแล้ว เจ้าหน้าที่จะแจ้งผลภายใน 1–2 วันทำการ"
    elsif saved
      Current.user.complete_onboarding_step!(@step)
      redirect_to onboarding_step_path(Current.user.next_onboarding_step(@step))
    else
      render :edit, status: :unprocessable_entity
    end
  end

  helper_method :skippable_step?

  private
    def skippable_step?
      @step.in?(SKIPPABLE_STEPS)
    end

    def require_pending_onboarding
      redirect_to root_path, notice: "ไม่มีข้อมูลที่ต้องกรอกเพิ่ม" unless Current.user.onboarding_pending?
    end

    def set_step
      @step = params[:step]
      @step_index = User::ONBOARDING_STEPS.index(@step)

      unless Current.user.onboarding_step_reachable?(@step)
        redirect_to onboarding_step_path(Current.user.current_onboarding_step)
      end
    end

    def load_step
      run_step_hook(:load)
    end

    def run_step_hook(kind, default: nil)
      hook = "#{kind}_#{@step}_step"
      respond_to?(hook, true) ? send(hook) : default
    end

    def adjacent_step(offset)
      User::ONBOARDING_STEPS[(@step_index + offset).clamp(0, User::ONBOARDING_STEPS.length - 1)]
    end
end
