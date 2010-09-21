require 'spec_helper'
require 'vcr/development_logger'

describe VCR::DevelopmentLogger, :focus => true do
  logging_dir = 'tmp/logging_dir'
  temp_dir logging_dir

  subject { described_class.new(logging_dir) }

  let(:main_file)                { File.join(logging_dir, 'http_interactions.yml') }
  let(:timestamped_file)         { File.join(logging_dir, 'http_interactions.2010-09-21_12-00-00.yml') }
  let(:example_http_interaction) { VCR::HTTPInteraction.new("request 1", "response 2") }

  around(:each) do |example|
    Timecop.freeze(Time.local(2010, 9, 21, 12), &example)
  end

  it 'creates the log directory' do
    expect { subject }.to change { File.exist?(logging_dir) }.from(false).to(true)
    File.should be_directory(logging_dir)
  end

  it 'symlinks http_interactions.yml to the timestamped yaml file' do
    subject
    File.readlink(main_file).should == File.basename(timestamped_file)
  end

  it 'symlinks http_interactions.yml to the timestamped yaml file even when the file has been previously symlinked' do
    Timecop.freeze(Time.now - 2.days) { described_class.new(logging_dir) }
    File.symlink?(main_file).should be_true
    subject
    File.readlink(main_file).should == File.basename(timestamped_file)
  end

  it 'logs http interactions directly to a timestamped yaml file' do
    subject
    File.zero?(timestamped_file).should be_true

    subject.log(example_http_interaction)
    subject.log(example_http_interaction)

    YAML.load(File.read(timestamped_file)).should == [example_http_interaction, example_http_interaction]
  end
end
