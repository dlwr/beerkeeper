require 'rails_helper'

RSpec.describe ErrorNotifier do
  include ActiveSupport::Testing::TimeHelpers

  let(:cache) { ActiveSupport::Cache::MemoryStore.new }
  let(:notifier) { described_class.new(to: 'owner@example.com', cache:) }

  def raised(error_class = RuntimeError, message = 'boom')
    raise error_class, message
  rescue error_class => e
    e
  end

  def report(error, handled: false)
    notifier.report(error, handled:, severity: :error, context: {}, source: 'application.action_dispatch')
  end

  before { ActionMailer::Base.deliveries.clear }

  it '未処理の例外をオーナーにメールする' do
    report(raised)

    mail = ActionMailer::Base.deliveries.last
    expect(mail.to).to eq [ 'owner@example.com' ]
    expect(mail.subject).to include('RuntimeError')
    expect(mail.body.decoded).to include('boom')
  end

  it '処理済みの例外は送らない' do
    report(raised, handled: true)

    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it '宛先が無ければ送らない' do
    described_class.new(to: nil, cache:).report(raised, handled: false, severity: :error, context: {})

    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it '同じ例外が続いても一定時間内は1通だけ送る' do
    error = raised
    3.times { report(error) }

    expect(ActionMailer::Base.deliveries.size).to eq 1
  end

  it '別の例外クラスなら別に送る' do
    report(raised)
    report(raised(ArgumentError))

    expect(ActionMailer::Base.deliveries.size).to eq 2
  end

  it '一定時間が過ぎれば同じ例外をまた送る' do
    error = raised
    report(error)

    travel(1.hour + 1.minute) { report(error) }

    expect(ActionMailer::Base.deliveries.size).to eq 2
  end

  it 'メール送信に失敗しても例外を外に出さない' do
    allow(ErrorMailer).to receive(:with).and_raise(Errno::ECONNREFUSED)

    expect { report(raised) }.not_to raise_error
  end
end
