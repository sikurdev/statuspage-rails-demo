module Admin
  class MonitorsController < BaseController
    before_action :set_monitor, only: %i[ show edit update destroy check ]

    def index
      @monitors = UptimeMonitor.ordered.includes(:incidents)
    end

    def show
      @check_results = @monitor.check_results.recent.limit(25)
      @incidents = @monitor.incidents.recent_first.limit(10)
    end

    def new
      @monitor = UptimeMonitor.new
    end

    def create
      @monitor = UptimeMonitor.new(monitor_params)
      if @monitor.save
        CheckMonitorJob.perform_later(@monitor)
        redirect_to admin_monitor_path(@monitor), notice: "Monitor created. First check queued."
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @monitor.update(monitor_params)
        redirect_to admin_monitor_path(@monitor), notice: "Monitor updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @monitor.destroy!
      redirect_to admin_monitors_path, notice: "Monitor deleted.", status: :see_other
    end

    def check
      CheckMonitorJob.perform_later(@monitor)
      redirect_to admin_monitor_path(@monitor), notice: "Check queued."
    end

    private
      def set_monitor
        @monitor = UptimeMonitor.find(params[:id])
      end

      def monitor_params
        params.expect(uptime_monitor: %i[ name url check_interval_seconds expected_status failure_threshold active ])
      end
  end
end
