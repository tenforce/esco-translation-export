get '/export' do
  ## The expot route allows the consumer to fetch a csv file that holds
  ## the following data for a given language:
  ##  uri, isco, pref label, [alt labels separated by |]
  ##
  ## the language can be set by passing a parameter language
  ## by default it is assumed to be en

  # checking the language
  label_language = "en"

  if params[:language]
    label_language = params[:language]
  end

  # the uri defining a concept
  conceptType = "<http://data.europa.eu/esco/model#Occupation>"

  # the uri defining a skill
  skillType = "<http://data.europa.eu/esco/model#Skill>"

  # perform a search on concepts by default
  toFetchType = conceptType

  if params[:type]
    if params[:type].to_s.eql? "skill"
      toFetchType = skillType
    end
  end

  # the concept query gets the uri of the concept and the isco group
  # under which it resides

  conceptQuery = "SELECT ?uri ?isco WHERE { \n" +
                 "?uri a " + toFetchType + " .\n" +
                 "?uri a <http://data.europa.eu/esco/model#MemberConcept> .\n"

  if params[:type].to_s.eql? "skill"
    conceptQuery += "OPTIONAL {"
  end

  conceptQuery += "?isco <http://www.w3.org/2004/02/skos/core#inScheme>"  +
                 "<http://data.europa.eu/esco/concept-scheme/isco> .\n" +
                  "?uri <http://data.europa.eu/esco/model#memberOfISCOGroup> ?isco .\n"

  if params[:type].to_s.eql? "skill"
    conceptQuery += "}"
  end

  conceptQuery += "\n} ORDER BY ?isco"

  puts conceptQuery

  # executing the query
  res = query(conceptQuery)

  # output_buffer serves as output buffer
  output_buffer = ""

  # loop over all rows
  res.each_solution do |solution|
    # add the uri, isco, to o
    output_buffer += "\"" + solution['uri'].to_s + "\",\"" + solution['isco'].to_s + "\",\""

    # the preflabel query will fetch all preflabels for a given uri
    # there can be more than one if there are multiple languages
    prefLabelQuery = "SELECT ?pref_label\n" +
                     "WHERE\n{\n" +
                     "<" + solution ['uri'] + "> <http://www.w3.org/2008/05/skos-xl#prefLabel> ?pturi .\n" +
                                    "?pturi <http://www.w3.org/2008/05/skos-xl#literalForm> ?pref_label .\n" +
                                    "FILTER(lang(?pref_label) = '" + label_language + "')\n" +
                                    "}"

    # the default value for the pref label is an empty string
    prefLabel = ""

    # executing the pref label query
    pref_res = query(prefLabelQuery)

    # looping over all pref labels
    pref_res.each_solution do |prefSolution|
      prefLabel = prefSolution['pref_label'].to_s
    end

    # # add the value of prefLabel to o (the output buffer)
    output_buffer += prefLabel + "\",\""

    # now we still need to get the alt labels:
    altLabelQuery = "SELECT ?alt_label\n" +
                    "WHERE\n" +
                    "{\n" +
                    "<" + solution['uri'] + "> <http://www.w3.org/2008/05/skos-xl#altLabel> ?alt_label_uri .\n" +
                    "?alt_label_uri <http://www.w3.org/2008/05/skos-xl#literalForm> ?alt_label . \n" +
                                    "FILTER(lang(?alt_label) = '" + label_language + "')\n" +
                    "}"


    # executing the query
    alt_res = query(altLabelQuery)

    # has_alt_labels is used after looping over all solutions since for every eligible alt label
    # we also add a | after it
    # this means that the last pipe will always have to be removed unless there were no eliible labels
    has_alt_labels = false

    # looping over all rows
    alt_res.each_solution do |altSolution|
      output_buffer += altSolution['alt_label'].to_s + "|"
    end

    # if alt labels were added then the last character is an | which should not be there
    if has_alt_labels
      output_buffer = output_buffer.byteslice(0..-2)
    end

    output_buffer += "\",\""

    # now we still need to get the hidden labels:
    hiddenLabelQuery = "SELECT ?hidden_label\n" +
                    "WHERE\n" +
                    "{\n" +
                    "<" + solution['uri'] + "> <http://www.w3.org/2008/05/skos-xl#hiddenLabel> ?hidden_label_uri .\n" +
                       "?hidden_label_uri <http://www.w3.org/2008/05/skos-xl#literalForm> ?hidden_label . \n" +
                       "FILTER(lang(?hidden_label) = '" + label_language + "')\n" +
                    "}"

    # executing the query
    hidden_res = query(hiddenLabelQuery)

    # has_hidden_labels is used after looping over all solutions since for every eligible hidden label
    # we also add a | after it
    # this means that the last pipe will always have to be removed unless there were no eligible labels
    has_hidden_labels = false

    # looping over all rows
    hidden_res.each_solution do |hiddenSolution|

      # if the hidden label has a language and that language is the desired language
      # if hiddenSolution['hidden_label'].has_language?
      #   if hiddenSolution['hidden_label'].language.to_s.eql? label_language

      #     # add it to the output buffer and set the has_hidden_labels variable to true
      #     output_buffer += hiddenSolution['hidden_label'].to_s + "|"
      #     has_hidden_labels = true
      #   end
      # end
      output_buffer += hiddenSolution['hidden_label'].to_s + "|"
    end

    # if hidden labels were added then the last character is an | which should not be there
    if has_hidden_labels
      output_buffer = output_buffer.byteslice(0..-2)
    end

    # add a new line after this concept has been handled
    output_buffer += "\"\n"
  end

  # return the output buffer
  output_buffer
end
