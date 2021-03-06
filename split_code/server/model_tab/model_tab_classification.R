######################
# Classification tab #

# checking if target has NAs
output$targetStillWithNAClass <- reactive({
  targetStillWithNAClass = (anyNA(v$data[,ncol(v$data)]) && !is.null(v$data[,ncol(v$data)]))
  return(targetStillWithNAClass)
})
outputOptions(output, 'targetStillWithNAClass', suspendWhenHidden = FALSE)
createAlert(session, 'targetWithNAClass', 
            title = '<i class="fa fa-info-circle" aria-hidden="true"></i> The selected Target has NA values!', 
            content = HTML('<p><b>Go to:</b>
                           <i>"Pre processing"</i> <i class="fa fa-long-arrow-right" aria-hidden="true"></i>
                           <i>"Manage Missing values"</i></p>'), 
            
            append = F,
            style = 'warning'
            )
# checking if target is constant
output$targetConstantClass <- reactive({
  targetConstantClass = (length(unique(v$data[,ncol(v$data)]))==1 && !anyNA(v$data[,ncol(v$data)]) && !is.null(v$data[,ncol(v$data)]))
  return(targetConstantClass)
})
outputOptions(output, 'targetConstantClass', suspendWhenHidden = FALSE)
createAlert(session, 'targetIsConstantClass', 
            title = '<i class="fa fa-info-circle" aria-hidden="true"></i> The selected Target is constant 
            and it cannot be predicted, please choose another target', 
            content = HTML('<p><b>Go to:</b>
                           <i>"Pre processing"</i> <i class="fa fa-long-arrow-right" aria-hidden="true"></i>
                           <i>"Merge"</i></p>
                           <p>Choose your merge options/target variable and run again <i>"Merge"</i></p>'), 
            
            append = F,
            style = 'warning'
            )


# checking if target can be predicted
output$targetWithoutNAClass <- reactive({
  targetWithoutNAClass = (!anyNA(v$data[,ncol(v$data)]) && !length(unique(v$data[,ncol(v$data)]))==1 && !is.null(v$data[,ncol(v$data)]))
  return(targetWithoutNAClass)
})
outputOptions(output, 'targetWithoutNAClass', suspendWhenHidden = FALSE)

# predictor sample rate
output$preSampleRateClass <- renderText({
  if (is.null(v$preRate)){
    return()
  }
  else{
    paste(v$preRate, 'Hz')
  }
})

# target sampling rate is updated in model_tab, while pressing merge button

# Adjusting max window size
observeEvent(input$numOfSamplesClass,{
  # Check preRate
  if(is.null(v$preRate)) {
    v$preRate <- 1
  }
  v$maxWinClass <- as.integer(v$preRate*(input$numOfSamplesClass))
  updateNumericInput(session, "maxWindowClass",
                     value = v$maxWinClass,
                     min = 0, max = 10*(v$maxWinClass), step = 1)
})

# Running Accordion:
observeEvent(input$goClass,{
  # Update sampling rate of predictors after pre-processing
  v$AIData <- analyseIndependentData(v$data[,-ncol(v$data)])
  v$AIData$Stable.Sampling.Rate <- "yes"
  # Update Accordion parameters according to the users preferences
  v$PParameter <- parameterFinder(v$AIData$Sampling.Rate, input$tarSampleRateClass, input$maxWindowClass)
  v$PParameter$nOperations <- input$numOfSamplesClass
  v$PParameter$Size <- round(seq(from=v$PParameter$Jump, to=input$maxWindowClass, length.out=v$PParameter$nOperations), digits = 0)
  
  # Downsample the target
  aTarIndex <- seq(from = v$PParameter$Jump, to = v$AIData$Variables.nrow, by = v$PParameter$Jump)
  
  # Run accordion
  v$features <- embeddedGainRatioFS(v$data[aTarIndex,ncol(v$data)], v$data[1:aTarIndex[length(aTarIndex)],-ncol(v$data)], v$AIData, v$PParameter)
  colnames(v$features)[1] <- v$selectedTarget
  timestamp <- v$data[aTarIndex,1]
  v$features <- cbind(timestamp, v$features)
  # print(summary(v$features))
  renderFeaturesClassDataTable(v$features)
})

# render feature data Class function
renderFeaturesClassDataTable <- function(data) {
  output$featuresClassDataTable <- renderUI({
    if (is.null(data)){
      fluidRow(box(
        width = 12,
        background ="red",
        tags$h4(icon('bullhorn'),"Features Data NULL!")
        #HTML("Please upload a dataset to start.")
      ))
    }
    else{
      output$featursDataClassTable0 <- DT::renderDataTable({
        DT::datatable(data, options = list(pageLength = 20))
      })
      DT::dataTableOutput('featursDataClassTable0')
    }
  })
  
  output$featuresClassDataSummary <- renderPrint({
    if (is.null(data))
      return()
    summary(data)
  })
}


###################################################
#                   Plot Features                 #
###################################################

# TODO: FIX bug for timestamps
# TODO: make it plot faster

# checking if target is NonNumerical to enable target's classes
output$classPlotcheckClass <- reactive({
  target = colnames(v$features)[1]
  isTargetNonNumericClass = (!is.numeric(v$features[,target]) 
                             && target %in% input$plotClassY)
  output$textClassSelectorClass <- renderText({
    paste("Select Target's classes:")
  })
  return(isTargetNonNumericClass)
})
outputOptions(output, 'classPlotcheckClass', suspendWhenHidden = FALSE)


# Event of clicking on Plot button
observeEvent(input$featuresClassPlot, {
  x <- input$plotClassX
  y <- input$plotClassY
  get_featuresClassPlot(input$featuresClassPlotType, v$features, x, y)
})


get_featuresClassPlot <- function(type, data, varX, varY){
  
  colorMax = 9
  colors = RColorBrewer::brewer.pal(colorMax, "Pastel1")
  
  # checking the output: dygraphOutput for simplePlot / uiOutput for other
  output$simplePlotCheckClass <- reactive({
    simpleClass = (input$featuresClassPlotType == 'simplePlotClass')
    return(simpleClass)
  })
  outputOptions(output, 'simplePlotCheckClass', suspendWhenHidden = FALSE)
  
  output$multiPlotCheckClass <- reactive({
    multiClass = (input$featuresClassPlotType == 'multiPlotClass')
    return(multiClass)
  })
  outputOptions(output, 'multiPlotCheckClass', suspendWhenHidden = FALSE)
  
  output$corrPlotCheckClass <- reactive({
    corrClass = (input$plotType == 'corrPlotClass')
    return(corrClass)
  })
  outputOptions(output, 'corrPlotCheckClass', suspendWhenHidden = FALSE)
  
  # Simple Plot
  output$plotClass <- renderDygraph({
    d <- data
    if (is.null(d)
        ||
        is.null(varY)
    )
    {
      return()
    }
    # dygraph:
    # where the first element/column provides x-axis values and
    # all subsequent elements/columns provide one or more series of y-values.
    
    # get selected X and Y
    if(varX == 'DataIndex'){
      DataIndex <- seq(from = 1, to = nrow(d))
      target <- cbind(DataIndex, d[varY])
    }
    else{
      target <- cbind(d[c(varX,varY)])
    }
    
    g <- dygraph(target)%>%
      dyLegend(show = "onmouseover", showZeroValues = TRUE, hideOnMouseOut = FALSE)
    
    # check which col have NA's
    varWithNA = colnames(target)[colSums(is.na(target)) > 0]
    
    # shading for the non-numerical Data
    for (n in colnames(target)) {
      if (!is.numeric(target[,n])) {
        # create an array with the start and end index of every class
        # using rle() function
        w = rle(as.vector(target[,n]))
        e=0
        l=c()
        for(i in 1:length(w$lengths)){
          s=e+1 #start point
          e=e+w$lengths[i] # end point
          # the array
          l=rbind(l,c(s,e,w$values[i]))
        }
        # shading
        classes = unique(l[,3])
        if(is.null(input$plotClassClass)){
          return(g)
        }
        else{
          k = 1
          for(x in input$plotClassClass){
            for(j in 1:nrow(l)){
              if(is.na(l[j,3]) | is.na(x)){
                check = FALSE
              }
              else{
                check = (x == l[j,3])
              }
              if (check){
                if(varX == 'DataIndex'){
                  g<-dyShading(g, from = l[j,1], to = l[j,2], color = colors[k %% colorMax+1])%>%
                    dyLegend(show = "onmouseover", showZeroValues = TRUE, hideOnMouseOut = FALSE)  
                }
                if(varX == colnames(v$data)[1]){
                  g<-dyShading(g, from = v$data[l[j,1],1], to = v$data[l[j,2],1], color = colors[k %% colorMax+1])%>%
                    dyLegend(show = "onmouseover", showZeroValues = TRUE, hideOnMouseOut = FALSE)  
                }
              }
            }
            k = k + 1
          }
        }
      }
    }
    return(g)
  })
  
  # Multi Plot
  output$multiClass <- renderUI({
    
    d <- data  
    if(is.null(varY)){
      return()
    }
    
    target_col = colnames(d)[1]
    nonNumericTargetClass = (!is.numeric(d[,target_col]) && target_col %in% varY)
    
    result_div <- div()
    out <- lapply(varY, function(i){
      if(i==target_col && nonNumericTargetClass){
        return()
      }
      else{
        if(nonNumericTargetClass){
          if(varX == 'DataIndex'){
            DataIndex <- seq(from = 1, to = nrow(d))
            target <- cbind(DataIndex, d[c(i,target_col)])
          }
          else{
            target <- d[c(varX,i,target_col)]
          }  
        }
        else{
          if(varX == 'DataIndex'){
            DataIndex <- seq(from = 1, to = nrow(d))
            target <- cbind(DataIndex, d[i])
          }
          else{
            target <- d[c(varX,i)]
          }
        }
      }
      
      # 1. create a container
      #     <div result/>
      #         <div for dygraph1/>
      #         <div for dygraph2/>
      #
      # 2. define output$dygraph1, output$dygraph2
      tempNameClass <- paste0("mulplot_dygraph_", i)
      
      # output$xxx mush be defined before uiOutput("xxx") to make it work
      output[[tempNameClass]] <- renderDygraph({
        
        g <- dygraph(target, main = i, group = 'mulplot') %>%
          dyLegend(show = "onmouseover", showZeroValues = TRUE, hideOnMouseOut = FALSE)%>%
          dyOptions(colors = "black")
        
        # shading for the non-numerical Data
        for (n in colnames(target)) {
          if (!is.numeric(target[,n])) {
            # create an array with the start and end index of every class
            # using rle() function
            w = rle(as.vector(target[,n]))
            e=0
            l=c()
            for(i in 1:length(w$lengths)){
              s=e+1 #start point
              e=e+w$lengths[i] # end point
              # the array
              l=rbind(l,c(s,e,w$values[i]))
            }
            
            # shading
            classes = unique(l[,3])
            if(is.null(input$plotClassClass)){
              return(g)
            }
            else{
              k = 1
              for(x in input$plotClassClass){
                for(j in 1:nrow(l)){
                  if(is.na(l[j,3]) | is.na(x)){
                    check = FALSE
                  }
                  else{
                    check = (x == l[j,3])
                  }
                  if (check){
                    if(varX == 'DataIndex'){
                      g<-dyShading(g, from = l[j,1], to = l[j,2], color = colors[k %% colorMax+1])%>%
                        dyLegend(show = "onmouseover", showZeroValues = TRUE, hideOnMouseOut = FALSE)  
                    }
                    if(varX == colnames(v$data)[1]){
                      g<-dyShading(g, from = v$data[l[j,1],1], to = v$data[l[j,2],1], color = colors[k %% colorMax+1])%>%
                        dyLegend(show = "onmouseover", showZeroValues = TRUE, hideOnMouseOut = FALSE)  
                    }
                  }
                }
                k = k + 1
              }
            }
          }
        }
        return(g)
      })
      dygraphOutput(tempNameClass, width = "100%", height = "300px")
      
    })
    
    result_div <- tagAppendChild(result_div, out)
    
  })
  # }
  
  # corelation plots
  output$corrClass <- renderUI({
    
    d <- data
    if(is.null(varY))
      return()
    
    result_div <- div()
    
    dop <- lapply(varY, function(i){
      
      if(varX == 'DataIndex'){
        DataIndex <- seq(from = 1, to = nrow(d))
        target <- cbind(DataIndex, d[i])
      }
      else{
        target <- d[c(varX,i)]
      }
      tempNameClass <- paste0("corplot_ggplot_", i)
      output[[tempNameClass]] <- renderPlot({
        ggplot(target, aes_string(x = varX, y = i)) +
          geom_point() +
          geom_smooth(method = "lm", se = F) +
          ggtitle(i)
      })
      plotOutput(tempNameClass, width = "100%", height = "300px")
      
    })
    result_div <- tagAppendChild(result_div, dop)
  })
}

