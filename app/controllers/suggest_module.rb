
# Base class for suggestions controllers
#class SuggestBaseController < ApplicationController
module SuggestModule

  MAX_SUGGEST_RESULTS = 5

  # Action to suggest table names
  def suggest
    respond_to do |format|
      format.json do
        # Get the model class for the controller
        model_class = Kernel.const_get(controller_name.classify)
        render json: suggest_class( model_class , MAX_SUGGEST_RESULTS )
      end
    end
  end

  def suggest_get_names( model_class , max_results , start_with )

    relation = model_class.all.limit(max_results)

    # If the controller is the player, do an inner join with the queue songs:
    #puts "*** #{controller_name.inspect}"
    if controller_name == 'player'
      if model_class.name == 'Songs'
        relation_field_name = 'id'
      else
        relation_field_name = model_class.name.singularize.camelize(:lower) + '_id'
      end
      subquery = current_play_list.play_list_songs.joins( :song ).select( relation_field_name )
      relation = relation.where( id: subquery )
    end

    # Filter by name
    name_condition = params[:term] + '%'
    name_condition = '%' + name_condition if !start_with
    relation = relation.where( 'name LIKE ?' , name_condition )

    return relation
      .order(:name)
      .pluck(:name)

  end

  def suggest_class( model_class , max_results )

    # Search starting by the text
    names = suggest_get_names( model_class , max_results , true )

    if names.length < max_results
      # Search at any position
      aux = suggest_get_names( model_class , max_results - names.length , false )
      names += aux
      names.uniq!
    end

    return names
  end

  # Action to suggest table names from different models
  # [+model_classes+] Array with the classes to suggest, sorted
  def suggest_classes( model_classes )

    names = []
    n_names_left = MAX_SUGGEST_RESULTS
    model_classes.each do |c|
      # Search results for this class
      class_results = suggest_class(c, n_names_left)
      # Join results, case insensitive:
      class_results.each do |r|
        names << r if !names.any?{ |s| s.casecmp( r ) == 0 }
      end
      # Check if we have finished
      n_names_left = MAX_SUGGEST_RESULTS - names.length
      break if n_names_left == 0
    end

    names.sort!

    respond_to do |format|
      format.json do
        render json: names
      end
    end

  end

end
