class ErrorMailer < ApplicationMailer
  def error_email
    @error = params[:error]
    @source = params[:source]

    mail to: params[:to], subject: "[beerkeeper] #{@error.class}: #{@error.message.to_s.truncate(80)}"
  end
end
