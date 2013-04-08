# Professor

Grades your changes based on best practices.

## Installation

    git clone git@source.flexilis.local:bschanfeldt/Professor.git
    cd Professor
    gem build professor.gemspec; gem install professor-0.0.1.pre.gem
    professor help

## Usage

Today the professor can help in three ways _everything_, _changes_, and _commit_

### Grade

    professor grade

A porcelain command to check changes or last commit based on the repo status.

#### Grade Everything

    professor grade everything

Grades the entire codebase, by default targets only ruby files in lib and app.

#### Grade Changes

    professor grade changes

Grades the files changed since last commit

#### Grade Commit

    professor grade commit

Grades the files changed in the most recent commit
