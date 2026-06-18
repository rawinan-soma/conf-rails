# frozen_string_literal: true

# ATDD Red-Phase Test Scaffolds — Story 1.1: Project Initialization & Platform Scaffold
#
# TDD RED PHASE: All tests are skipped until implementation is complete.
# To activate: remove the `skip` call for the task you are currently implementing,
# run `bundle exec rails test test/integration/project_scaffold_test.rb`,
# verify the test FAILS first (red), implement the feature, then verify it PASSES (green).
#
# Acceptance Criteria Covered:
#   AC-1: Rails 8 boots with PostgreSQL + Tailwind+daisyUI (no Node); .gitignore correct
#   AC-2: CI pipeline runs all 6 gates and fails on high/critical findings
#   AC-3: Kamal 2 + Thruster deploy config — no secrets in source

require "test_helper"

class ProjectScaffoldTest < ActiveSupport::TestCase
  # ---------------------------------------------------------------------------
  # AC-1: .gitignore covers required credential patterns (P0, R-002)
  # ---------------------------------------------------------------------------

  test "[P0] .gitignore excludes master.key" do
    skip "ATDD RED PHASE — implement Story 1.1 Task 4 (.gitignore) first"
    gitignore = File.read(Rails.root.join(".gitignore"))
    assert_match %r{^config/master\.key$}m, gitignore,
                 ".gitignore must contain 'config/master.key'"
  end

  test "[P0] .gitignore excludes credentials key files" do
    skip "ATDD RED PHASE — implement Story 1.1 Task 4 (.gitignore) first"
    gitignore = File.read(Rails.root.join(".gitignore"))
    assert_match %r{config/credentials/\*\.key}m, gitignore,
                 ".gitignore must contain 'config/credentials/*.key'"
  end

  test "[P0] .gitignore excludes .env files" do
    skip "ATDD RED PHASE — implement Story 1.1 Task 4 (.gitignore) first"
    gitignore = File.read(Rails.root.join(".gitignore"))
    assert_match %r{^\.env(\.\*)?$}m, gitignore,
                 ".gitignore must contain '.env' and '.env.*'"
  end

  test "[P0] .gitignore excludes .pem files" do
    skip "ATDD RED PHASE — implement Story 1.1 Task 4 (.gitignore) first"
    gitignore = File.read(Rails.root.join(".gitignore"))
    assert_match %r{\*\.pem}m, gitignore,
                 ".gitignore must contain '*.pem'"
  end

  # ---------------------------------------------------------------------------
  # AC-1: Rails application configuration (P1)
  # ---------------------------------------------------------------------------

  test "[P1] application is configured for Bangkok timezone" do
    skip "ATDD RED PHASE — implement Story 1.1 Task 1 (generate Rails app) first"
    assert_equal "Bangkok", Rails.application.config.time_zone,
                 "config.time_zone must be 'Bangkok'"
  end

  test "[P1] application default locale is English" do
    skip "ATDD RED PHASE — implement Story 1.1 Task 1 (generate Rails app) first"
    assert_equal :en, Rails.application.config.i18n.default_locale,
                 "config.i18n.default_locale must be :en"
  end

  test "[P1] application available locales include English and Thai" do
    skip "ATDD RED PHASE — implement Story 1.1 Task 8 (i18n structure) first"
    assert_includes Rails.application.config.i18n.available_locales, :en
    assert_includes Rails.application.config.i18n.available_locales, :th
  end

  test "[P1] database adapter is PostgreSQL" do
    skip "ATDD RED PHASE — implement Story 1.1 Task 1 (generate Rails app with --database=postgresql) first"
    assert_equal "postgresql", ActiveRecord::Base.connection_db_config.adapter,
                 "database.yml must configure the postgresql adapter"
  end

  # ---------------------------------------------------------------------------
  # AC-1: daisyUI bundled files committed (no Node/CDN) (P1, R-010)
  # ---------------------------------------------------------------------------

  test "[P1] daisyui.mjs is committed to app/assets/tailwind" do
    skip "ATDD RED PHASE — implement Story 1.1 Task 2 (daisyUI no-Node setup) first"
    assert File.exist?(Rails.root.join("app/assets/tailwind/daisyui.mjs")),
           "daisyui.mjs must be committed to app/assets/tailwind/ (no CDN)"
  end

  test "[P1] daisyui-theme.mjs is committed to app/assets/tailwind" do
    skip "ATDD RED PHASE — implement Story 1.1 Task 2 (daisyUI no-Node setup) first"
    assert File.exist?(Rails.root.join("app/assets/tailwind/daisyui-theme.mjs")),
           "daisyui-theme.mjs must be committed to app/assets/tailwind/ (no CDN)"
  end

  test "[P1] application.css imports tailwindcss and daisyUI plugins" do
    skip "ATDD RED PHASE — implement Story 1.1 Task 2 (daisyUI no-Node setup) first"
    css = File.read(Rails.root.join("app/assets/tailwind/application.css"))
    assert_match '@import "tailwindcss"', css,
                 "application.css must contain '@import \"tailwindcss\"'"
    assert_match '@plugin "./daisyui.mjs"', css,
                 "application.css must contain '@plugin \"./daisyui.mjs\"'"
    assert_match '@plugin "./daisyui-theme.mjs"', css,
                 "application.css must contain '@plugin \"./daisyui-theme.mjs\"'"
    assert_match '@source not "./daisyui{,*}.mjs"', css,
                 "application.css must exclude daisyUI source from Tailwind scanning"
  end

  test "[P1] no node_modules directory exists at project root" do
    skip "ATDD RED PHASE — verify no Node dependency has been introduced"
    refute Dir.exist?(Rails.root.join("node_modules")),
           "node_modules must not exist — architecture requires zero Node/npm"
  end

  test "[P1] package.json does not exist at project root" do
    skip "ATDD RED PHASE — verify no Node dependency has been introduced"
    refute File.exist?(Rails.root.join("package.json")),
           "package.json must not exist — architecture requires zero Node/npm"
  end

  # ---------------------------------------------------------------------------
  # AC-2: CI pipeline declares all required gates (P0, R-002)
  # ---------------------------------------------------------------------------

  test "[P0] CI workflow file exists at .github/workflows/ci.yml" do
    skip "ATDD RED PHASE — implement Story 1.1 Task 5 (GitHub Actions CI workflow) first"
    assert File.exist?(Rails.root.join(".github/workflows/ci.yml")),
           ".github/workflows/ci.yml must exist"
  end

  test "[P0] CI workflow includes RuboCop step" do
    skip "ATDD RED PHASE — implement Story 1.1 Task 5 (GitHub Actions CI workflow) first"
    ci_yml = File.read(Rails.root.join(".github/workflows/ci.yml"))
    assert_match "rubocop", ci_yml,
                 "CI workflow must include a RuboCop step"
  end

  test "[P0] CI workflow includes Brakeman step" do
    skip "ATDD RED PHASE — implement Story 1.1 Task 5 (GitHub Actions CI workflow) first"
    ci_yml = File.read(Rails.root.join(".github/workflows/ci.yml"))
    assert_match "brakeman", ci_yml,
                 "CI workflow must include a Brakeman step"
  end

  test "[P0] CI workflow includes bundler-audit step" do
    skip "ATDD RED PHASE — implement Story 1.1 Task 5 (GitHub Actions CI workflow) first"
    ci_yml = File.read(Rails.root.join(".github/workflows/ci.yml"))
    assert_match "bundler-audit", ci_yml,
                 "CI workflow must include a bundler-audit step"
  end

  test "[P0] CI workflow includes gitleaks step" do
    skip "ATDD RED PHASE — implement Story 1.1 Task 5 (GitHub Actions CI workflow) first"
    ci_yml = File.read(Rails.root.join(".github/workflows/ci.yml"))
    assert_match "gitleaks", ci_yml,
                 "CI workflow must include a gitleaks step"
  end

  test "[P0] CI workflow includes Minitest step" do
    skip "ATDD RED PHASE — implement Story 1.1 Task 5 (GitHub Actions CI workflow) first"
    ci_yml = File.read(Rails.root.join(".github/workflows/ci.yml"))
    assert_match(/rails test|bundle exec rails test/i, ci_yml),
                 "CI workflow must run the Minitest suite"
  end

  test "[P0] CI workflow includes i18n-tasks health step" do
    skip "ATDD RED PHASE — implement Story 1.1 Task 5 (GitHub Actions CI workflow) first"
    ci_yml = File.read(Rails.root.join(".github/workflows/ci.yml"))
    assert_match "i18n-tasks", ci_yml,
                 "CI workflow must run i18n-tasks health check"
  end

  # ---------------------------------------------------------------------------
  # AC-3: Kamal deploy config — no secrets in source (P0, R-002, R-014)
  # ---------------------------------------------------------------------------

  test "[P0] config/deploy.yml exists" do
    skip "ATDD RED PHASE — implement Story 1.1 Task 6 (Kamal 2 + Thruster deploy) first"
    assert File.exist?(Rails.root.join("config/deploy.yml")),
           "config/deploy.yml must exist for Kamal 2 configuration"
  end

  test "[P0] config/deploy.yml contains no hardcoded secret values" do
    skip "ATDD RED PHASE — implement Story 1.1 Task 6 (Kamal 2 + Thruster deploy) first"
    deploy_yml = File.read(Rails.root.join("config/deploy.yml"))

    # Secrets must be referenced via ENV or Kamal secret references, never hardcoded
    refute_match(/password:\s+["']?[A-Za-z0-9!@#$%^&*]{8,}/, deploy_yml,
                 "deploy.yml must not contain a hardcoded password value")
    refute_match(/secret:\s+["']?[A-Za-z0-9!@#$%^&*]{8,}/, deploy_yml,
                 "deploy.yml must not contain a hardcoded secret value")
    refute_match(/private_key:\s+["']?[A-Za-z0-9!@#$%^&*]{8,}/, deploy_yml,
                 "deploy.yml must not contain a hardcoded private key")
  end

  test "[P0] Dockerfile exists for Kamal 2 deployment" do
    skip "ATDD RED PHASE — implement Story 1.1 Task 6 (Kamal 2 + Thruster deploy) first"
    assert File.exist?(Rails.root.join("Dockerfile")),
           "Dockerfile must exist (Rails 8 default + Thruster entrypoint)"
  end

  # ---------------------------------------------------------------------------
  # AC-1: Gemfile includes required gems (P1)
  # ---------------------------------------------------------------------------

  test "[P1] Gemfile includes required runtime gems" do
    skip "ATDD RED PHASE — implement Story 1.1 Task 3 (Gemfile) first"
    gemfile = File.read(Rails.root.join("Gemfile"))
    %w[pg omniauth_openid_connect pundit view_component prawn rqrcode
       solid_queue solid_cache solid_cable tailwindcss-rails lograge].each do |gem_name|
      assert_match gem_name, gemfile,
                   "Gemfile must include the '#{gem_name}' gem"
    end
  end

  test "[P1] Gemfile includes required development/test gems" do
    skip "ATDD RED PHASE — implement Story 1.1 Task 3 (Gemfile) first"
    gemfile = File.read(Rails.root.join("Gemfile"))
    %w[rubocop-rails-omakase brakeman bundler-audit i18n-tasks].each do |gem_name|
      assert_match gem_name, gemfile,
                   "Gemfile must include the '#{gem_name}' gem in development/test group"
    end
  end

  test "[P1] Gemfile does not include forbidden gems" do
    skip "ATDD RED PHASE — implement Story 1.1 Task 3 (Gemfile) first"
    gemfile = File.read(Rails.root.join("Gemfile"))
    refute_match(/^\s*gem ['"]rspec/, gemfile,
                 "Gemfile must NOT include RSpec — Minitest is the confirmed framework")
    refute_match(/^\s*gem ['"]redis/, gemfile,
                 "Gemfile must NOT include Redis — infrastructure is DB-backed (Solid Queue/Cache/Cable)")
  end

  # ---------------------------------------------------------------------------
  # AC-1: btree_gist extension migration (P1)
  # ---------------------------------------------------------------------------

  test "[P1] btree_gist extension migration exists" do
    skip "ATDD RED PHASE — implement Story 1.1 Task 7 (btree_gist migration) first"
    migration_files = Dir.glob(Rails.root.join("db/migrate/*enable_btree*.rb"))
    assert migration_files.any?,
           "A migration enabling btree_gist extension must exist in db/migrate/"
  end

  test "[P1] btree_gist extension is enabled in the database schema" do
    skip "ATDD RED PHASE — implement Story 1.1 Task 7 (btree_gist migration) first; run db:migrate"
    # Check schema.rb for btree_gist enable_extension declaration
    schema = File.read(Rails.root.join("db/schema.rb"))
    assert_match 'enable_extension "btree_gist"', schema,
                 "db/schema.rb must include enable_extension \"btree_gist\" after running the migration"
  end

  # ---------------------------------------------------------------------------
  # AC-1: i18n locale files (P1, R-007)
  # ---------------------------------------------------------------------------

  test "[P1] en.yml locale file exists" do
    skip "ATDD RED PHASE — implement Story 1.1 Task 8 (i18n structure) first"
    assert File.exist?(Rails.root.join("config/locales/en.yml")),
           "config/locales/en.yml must exist"
  end

  test "[P1] th.yml locale file exists as key-mirror stub" do
    skip "ATDD RED PHASE — implement Story 1.1 Task 8 (i18n structure) first"
    assert File.exist?(Rails.root.join("config/locales/th.yml")),
           "config/locales/th.yml must exist as a key-mirror stub for Thai"
  end

  # ---------------------------------------------------------------------------
  # AC-1: Solid Queue configuration (P1)
  # ---------------------------------------------------------------------------

  test "[P1] config/queue.yml exists for Solid Queue" do
    skip "ATDD RED PHASE — implement Story 1.1 Task 9 (Solid Queue configuration) first"
    assert File.exist?(Rails.root.join("config/queue.yml")),
           "config/queue.yml must exist for Solid Queue configuration"
  end

  test "[P1] config/recurring.yml stub exists" do
    skip "ATDD RED PHASE — implement Story 1.1 Task 9 (Solid Queue configuration) first"
    assert File.exist?(Rails.root.join("config/recurring.yml")),
           "config/recurring.yml stub must exist (recurring jobs added in Story 1.6)"
  end

  # ---------------------------------------------------------------------------
  # AC-1: ApplicationMailer scaffold (P2)
  # ---------------------------------------------------------------------------

  test "[P2] ApplicationMailer exists" do
    skip "ATDD RED PHASE — implement Story 1.1 Task 9 (ApplicationMailer scaffold) first"
    assert defined?(ApplicationMailer), "ApplicationMailer class must be defined"
  end

  test "[P2] ApplicationMailer inherits ActionMailer::Base" do
    skip "ATDD RED PHASE — implement Story 1.1 Task 9 (ApplicationMailer scaffold) first"
    assert ApplicationMailer < ActionMailer::Base,
           "ApplicationMailer must inherit from ActionMailer::Base"
  end

  # ---------------------------------------------------------------------------
  # AC-1: ApplicationController minimal scaffold (P2)
  # ---------------------------------------------------------------------------

  test "[P2] ApplicationController exists and inherits ActionController::Base" do
    skip "ATDD RED PHASE — implement Story 1.1 Task 9 (ApplicationController scaffold) first"
    assert defined?(ApplicationController), "ApplicationController class must be defined"
    assert ApplicationController < ActionController::Base,
           "ApplicationController must inherit from ActionController::Base"
  end

  test "[P2] ApplicationController does not include Pundit::Authorization at this stage" do
    skip "ATDD RED PHASE — Pundit wiring is Story 1.4; verify ApplicationController is minimal at Story 1.1"
    ancestors = ApplicationController.ancestors
    refute_includes ancestors, Pundit::Authorization,
                    "ApplicationController must NOT include Pundit::Authorization in Story 1.1 (that is Story 1.4)"
  end
end
