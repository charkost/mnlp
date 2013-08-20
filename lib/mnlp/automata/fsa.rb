# coding: utf-8
require 'active_support/all'

module Mnlp
  module Automata
    class Fsa

      attr_reader :states, :current_state, :recognize

      # @param options [Hash] initialization options
      # @option options [Fixnum] :number_of_states The initial number of states
      def initialize(options = {})
        options = defaults.merge(options)
        @states      = []
        options[:number_of_states].times { add_state }
        @current_state = 0

        # @todo Remove this attribute
        @recognize     = ""
      end

      def add_state
        @states.push State.new(suffix: states.size)
      end

      def alphabet
        states.map(&:alphabet).reduce(Set.new) { |a, v| a += v }
      end

      def has_state?(name)
        find_state(name).present?
      end

      def find_state(name)
        states.select { |state| state.name == name }.first
      end

      def create_transition(from, to, symbol)
        raise NoStateError if !has_state?(from) || !has_state?(to)
        from_state = find_state(from)
        to_state   = find_state(to)

        from_state.create_transition(to_state, symbol)
      end

      # @todo Move logic to State class
      def transition_table
        return @_transition_table if @_transition_table
        table = {}
        states.each_with_index do |state, index|
          table[index] = Hash[state.transitions.map { |t| [t.symbol, states.index(t.to)] }]
        end

        @_transition_table = table
      end

      # @todo Move some logic to State class
      def recognize!(symbol)
        if alphabet.include?(symbol) && transition_table[current_state].keys.include?(symbol)
          @current_state = transition_table[current_state][symbol]
          if states[current_state].final_state?
            #puts "RECOGNIZE #@recognition"
            @recognize = true
            return
          end
        else
          @current_state = 0
        end

        @recognize = false
      end

      private

      def defaults
        { number_of_states: 1 }
      end
    end
  end
end
