// lib/src/providers/actions/park_actions.dart
import 'package:arcane/src/providers/game_provider.dart';
import 'package:arcane/src/models/game_models.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:arcane/src/utils/constants.dart';
import 'package:collection/collection.dart'; // For firstWhereOrNull
import 'dart:math'; // For Random

class ParkActions {
  final GameProvider _provider;
  final Random _random = Random();


  ParkActions(this._provider);

  void _logToPark(String message, {bool isError = false}) {
    final color = isError ? AppTheme.fhAccentRed : AppTheme.fhAccentGreen;
    final logMessage = "<span style=\"color:${color.value.toRadixString(16).substring(2)};\">[Park] $message</span>";
    print("[ParkActions Log] $message");
    _provider.setProviderState(
        currentGame: CurrentGame(
            enemy: _provider.currentGame.enemy,
            playerCurrentHp: _provider.currentGame.playerCurrentHp,
            log: [..._provider.currentGame.log, logMessage],
            currentPlaceKey: _provider.currentGame.currentPlaceKey),
        doPersist: false,
        doNotify: true
    );
  }

  bool canAffordBuilding(BuildingTemplate buildingTemplate) {
    return _provider.parkManager.parkDollars >= buildingTemplate.costDollars;
  }

  void buyAndPlaceBuilding(String buildingTemplateId) {
    final template = _provider.buildingTemplatesList.firstWhereOrNull((t) => t.id == buildingTemplateId);
    if (template == null) {
      _logToPark("Error: Building blueprint not found.", isError: true);
      return;
    }

    if (!canAffordBuilding(template)) {
      _logToPark("Cannot afford ${template.name}. Cost: \$${template.costDollars}.", isError: true);
      return;
    }

    bool canBeOperationalInitially = true;
    if ((template.powerRequired ?? 0) > 0 && template.type != "power_plant") {
        final totalPowerGenerated = _provider.parkManager.currentPowerGenerated;
        final totalPowerConsumedByOthers = _provider.parkManager.currentPowerConsumed;

        if (totalPowerGenerated < totalPowerConsumedByOthers + (template.powerRequired ?? 0)) {
            canBeOperationalInitially = false;
            _logToPark("${template.name} constructed but offline due to insufficient power.", isError: true);
        }
    }


    final newBuilding = OwnedBuilding(
      uniqueId: 'ob_${DateTime.now().millisecondsSinceEpoch}_${template.id.hashCode}',
      templateId: template.id,
      currentFoodLevel: template.type == "food_station" ? enclosureBaseFoodCapacity : null,
      isOperational: template.type == "power_plant" ? true : canBeOperationalInitially,
    );

    final List<OwnedBuilding> updatedOwnedBuildings = [..._provider.ownedBuildings, newBuilding];
    final double newParkDollars = _provider.parkManager.parkDollars - template.costDollars;

    _provider.setProviderState(
      parkManager: _provider.parkManager..parkDollars = newParkDollars,
      ownedBuildings: updatedOwnedBuildings,
      doPersist: true,
      doNotify: true,
    );

    _logToPark("Constructed ${template.name}!");
    _recalculateParkStats(); // This will also update power status
  }

  void sellBuilding(String ownedBuildingUniqueId) {
    final ownedBuilding = _provider.ownedBuildings.firstWhereOrNull((b) => b.uniqueId == ownedBuildingUniqueId);
    if (ownedBuilding == null) {
        _logToPark("Error: Building not found in park.", isError: true);
        return;
    }
    final template = _provider.buildingTemplatesList.firstWhereOrNull((t) => t.id == ownedBuilding.templateId);
    if (template == null) {
        _logToPark("Error: Building blueprint corrupted for owned building.", isError: true);
        return;
    }

    final double sellPercentage = 0.5;
    final int sellPrice = (template.costDollars * sellPercentage).floor();

    List<OwnedBuilding> updatedOwnedBuildings = _provider.ownedBuildings.where((b) => b.uniqueId != ownedBuildingUniqueId).toList();
    final double newParkDollars = _provider.parkManager.parkDollars + sellPrice;
    List<OwnedDinosaur> updatedOwnedDinosaurs = List.from(_provider.ownedDinosaurs);

    if (template.type == "enclosure" && ownedBuilding.dinosaurUniqueIds.isNotEmpty) {
        updatedOwnedDinosaurs = _provider.ownedDinosaurs
            .where((dino) => !ownedBuilding.dinosaurUniqueIds.contains(dino.uniqueId))
            .toList();
        _logToPark("Dinosaurs from demolished ${template.name} have been released to the wild (removed from park).", isError: true);
    }

    _provider.setProviderState(
      parkManager: _provider.parkManager..parkDollars = newParkDollars,
      ownedBuildings: updatedOwnedBuildings,
      ownedDinosaurs: template.type == "enclosure" ? updatedOwnedDinosaurs : null, // Only update if it was an enclosure
      doPersist: true,
      doNotify: true,
    );
    _logToPark("Demolished ${template.name}. Recovered \$${sellPrice}.");
    _recalculateParkStats();
  }

  void excavateFossil(String speciesId) {
    final species = _provider.dinosaurSpeciesList.firstWhereOrNull((s) => s.id == speciesId);
    if (species == null) {
        _logToPark("Species $speciesId not found for excavation.", isError: true);
        return;
    }
     final bool fossilCenterOperational = _provider.ownedBuildings.any((b) {
        final template = _provider.buildingTemplatesList.firstWhereOrNull((t) => t.id == b.templateId);
        return template?.type == "fossil_center" && b.isOperational;
    });
    if (!fossilCenterOperational) {
        _logToPark("Fossil Center is not operational. Cannot excavate.", isError: true);
        return;
    }

    if (_provider.playerEnergy < species.fossilExcavationEnergyCost) { // Use player energy
      _logToPark("Not enough player energy to excavate. Cost: ${species.fossilExcavationEnergyCost}⚡", isError: true);
      return;
    }

    final recordIndex = _provider.fossilRecords.indexWhere((fr) => fr.speciesId == speciesId);
    if (recordIndex == -1) {
      _logToPark("Fossil record for species $speciesId not found.", isError: true);
      return;
    }
    final record = _provider.fossilRecords[recordIndex];
    if (record.isGenomeComplete) {
      _logToPark("Genome for ${record.speciesId} is already complete.", isError: false);
      return;
    }

    final double progressIncrease = 10.0 + _random.nextDouble() * 15.0; // 10-25% progress
    record.excavationProgress = (record.excavationProgress + progressIncrease).clamp(0.0, 100.0);
    if (record.excavationProgress >= 100.0) {
      record.isGenomeComplete = true;
      _logToPark("Genome for ${record.speciesId} is now 100% complete and ready for incubation!");
    } else {
      _logToPark("Fossil excavation for ${record.speciesId} progressed to ${record.excavationProgress.toStringAsFixed(1)}%.");
    }
    
    final List<FossilRecord> updatedRecords = List.from(_provider.fossilRecords);
    updatedRecords[recordIndex] = record;

    _provider.setProviderState(
      fossilRecords: updatedRecords,
      playerEnergy: _provider.playerEnergy - species.fossilExcavationEnergyCost, // Deduct player energy
      doPersist: true,
      doNotify: true
    );
  }

  void incubateDinosaur(String speciesId) {
    final species = _provider.dinosaurSpeciesList.firstWhereOrNull((s) => s.id == speciesId);
    if (species == null) {
      _logToPark("Species $speciesId not found for incubation.", isError: true);
      return;
    }
    final fossilRecord = _provider.fossilRecords.firstWhereOrNull((fr) => fr.speciesId == speciesId);
    if (fossilRecord == null || !fossilRecord.isGenomeComplete) {
      _logToPark("Genome for ${species.name} is not complete. Excavate more fossils.", isError: true);
      return;
    }
    if (_provider.parkManager.parkDollars < species.incubationCostDollars) {
      _logToPark("Not enough park funds to incubate ${species.name}. Cost: \$${species.incubationCostDollars}.", isError: true);
      return;
    }
    if (_provider.playerEnergy < incubationEnergyCost) { // Use player energy
       _logToPark("Not enough player energy to incubate ${species.name}. Cost: $incubationEnergyCost⚡.", isError: true);
      return;
    }

    // Check if a hatchery is available and has capacity
    final operationalHatcheries = _provider.ownedBuildings.where((b) {
        final template = _provider.buildingTemplatesList.firstWhereOrNull((t) => t.id == b.templateId);
        return template?.type == "hatchery" && b.isOperational;
    }).toList();

    if (operationalHatcheries.isEmpty) {
        _logToPark("No operational hatchery available to incubate dinosaurs.", isError: true);
        return;
    }
    
    int totalHatcheryCapacity = operationalHatcheries.fold(0, (sum, hatchery) {
        final template = _provider.buildingTemplatesList.firstWhereOrNull((t) => t.id == hatchery.templateId);
        return sum + (template?.capacity ?? 0);
    });
    
    final incubatingDinosCount = _provider.ownedDinosaurs.where((d) => d.name.contains("(Incubating)")).length;
    if (incubatingDinosCount >= totalHatcheryCapacity) {
         _logToPark("All hatcheries are at full capacity. Wait for current incubations to finish.", isError: true);
        return;
    }


    final newDinosaur = OwnedDinosaur(
      uniqueId: 'dino_${DateTime.now().millisecondsSinceEpoch}_${species.id.hashCode}',
      speciesId: species.id,
      name: "${species.name} (Incubating)", // Indicate status
      age: 0, // Represents incubation progress
    );

    _provider.setProviderState(
      parkManager: _provider.parkManager..parkDollars -= species.incubationCostDollars,
      playerEnergy: _provider.playerEnergy - incubationEnergyCost, // Deduct player energy
      ownedDinosaurs: [..._provider.ownedDinosaurs, newDinosaur],
      doPersist: true,
      doNotify: true
    );
    _logToPark("Incubation started for a ${species.name}!");
  }

  void addDinosaurToEnclosure(String dinosaurUniqueId, String enclosureUniqueId) {
    final dinosaur = _provider.ownedDinosaurs.firstWhereOrNull((d) => d.uniqueId == dinosaurUniqueId);
    final enclosure = _provider.ownedBuildings.firstWhereOrNull((b) => b.uniqueId == enclosureUniqueId);
    final enclosureTemplate = enclosure != null ? _provider.buildingTemplatesList.firstWhereOrNull((t) => t.id == enclosure.templateId) : null;

    if (dinosaur == null || enclosure == null || enclosureTemplate == null || enclosureTemplate.type != "enclosure") {
      _logToPark("Invalid dinosaur or enclosure for transfer.", isError: true);
      return;
    }
    if (!enclosure.isOperational) {
        _logToPark("${enclosureTemplate.name} is not operational. Cannot add dinosaurs.", isError: true);
        return;
    }
    if (enclosure.dinosaurUniqueIds.length >= (enclosureTemplate.capacity ?? 999)) {
        _logToPark("${enclosureTemplate.name} is at full capacity.", isError: true);
        return;
    }
    if(dinosaur.name.contains("(Incubating)")) {
        _logToPark("${dinosaur.name} is still incubating and cannot be moved.", isError: true);
        return;
    }


    final List<OwnedBuilding> updatedBuildings = _provider.ownedBuildings.map((b) {
      if (b.uniqueId == enclosureUniqueId) {
        return OwnedBuilding(
          uniqueId: b.uniqueId,
          templateId: b.templateId,
          dinosaurUniqueIds: [...b.dinosaurUniqueIds, dinosaurUniqueId],
          currentFoodLevel: b.currentFoodLevel,
          isOperational: b.isOperational,
        );
      }
      return b;
    }).toList();

    _provider.setProviderState(
      ownedBuildings: updatedBuildings,
      doPersist: true,
      doNotify: true
    );
    _logToPark("${dinosaur.name} moved to ${enclosureTemplate.name}.");
    _recalculateParkStats();
  }

  void feedDinosaursInEnclosure(String enclosureUniqueId, int amount) {
    final enclosure = _provider.ownedBuildings.firstWhereOrNull((b) => b.uniqueId == enclosureUniqueId);
     if (enclosure == null) {
        _logToPark("Enclosure not found for feeding.", isError: true);
        return;
    }
    // Find an associated food station. Simplified: assumes one generic food station for the park or per enclosure.
    // For more complex scenarios, link food stations to enclosures.
    final foodStationIndex = _provider.ownedBuildings.indexWhere((b) {
        final template = _provider.buildingTemplatesList.firstWhereOrNull((t) => t.id == b.templateId);
        // Assuming food stations are generic for now and not tied to specific enclosures in data model
        // If they were, would add: && b.linkedEnclosureId == enclosureUniqueId
        return template?.type == "food_station" && b.isOperational; 
    });

    if (foodStationIndex == -1) {
        _logToPark("No operational food station found.", isError: true); // Generic message if not linked
        return;
    }
    if (_provider.playerEnergy < feedDinoEnergyCost) { // Check player energy
        _logToPark("Not enough player energy to refill feeder. Cost: $feedDinoEnergyCost⚡", isError: true);
        return;
    }
    
    final List<OwnedBuilding> updatedBuildings = List.from(_provider.ownedBuildings);
    final foodStation = updatedBuildings[foodStationIndex];
    final newFoodLevel = (foodStation.currentFoodLevel ?? 0) + amount;
    updatedBuildings[foodStationIndex] = OwnedBuilding(
        uniqueId: foodStation.uniqueId,
        templateId: foodStation.templateId,
        dinosaurUniqueIds: foodStation.dinosaurUniqueIds,
        currentFoodLevel: newFoodLevel.clamp(0, enclosureBaseFoodCapacity),
        isOperational: foodStation.isOperational
    );

    _provider.setProviderState(
        ownedBuildings: updatedBuildings,
        playerEnergy: _provider.playerEnergy - feedDinoEnergyCost, // Deduct player energy
        doPersist: true,
        doNotify: true
    );
    _logToPark("Refilled food by $amount. New level: ${updatedBuildings[foodStationIndex].currentFoodLevel}.");
  }

  void toggleBuildingOperationalStatus(String ownedBuildingUniqueId) {
    final ownedBuilding = _provider.ownedBuildings.firstWhereOrNull((b) => b.uniqueId == ownedBuildingUniqueId);
    if (ownedBuilding == null) return;
    final template = _provider.buildingTemplatesList.firstWhereOrNull((t) => t.id == ownedBuilding.templateId);
    if (template == null) return;

    bool currentStatus = ownedBuilding.isOperational;
    bool newStatus = !currentStatus;
    List<OwnedBuilding> tempUpdatedBuildings = List.from(_provider.ownedBuildings);
    int buildingIndex = tempUpdatedBuildings.indexWhere((b) => b.uniqueId == ownedBuildingUniqueId);

    if (newStatus) { // Attempting to turn ON
        if ((template.powerRequired ?? 0) > 0) { // Only check for consumers
            int totalPowerGenerated = _provider.parkManager.currentPowerGenerated;
            // If the building being turned on IS a power plant, its output is not yet in totalPowerGenerated.
            // So, we add its potential output if it's the one being toggled.
            if (template.type == "power_plant") {
                // This case is fine, power plants don't consume to turn on
            } else { // Consumer building
                int currentTotalPowerConsumedByOthers = _provider.parkManager.currentPowerConsumed;
                // If the building was already on and included in currentPowerConsumed, this check is slightly off,
                // but the goal is to check if turning *this one* on exceeds generation.
                // A more precise `currentPowerConsumed` would exclude this building if it was already on.
                // However, `_updateBuildingOperationalStatusBasedOnPower` will correct things.
                if (totalPowerGenerated < currentTotalPowerConsumedByOthers + (template.powerRequired ?? 0)) {
                    _logToPark("Cannot turn on ${template.name}. Insufficient power. Available: $totalPowerGenerated, Required (incl. this): ${currentTotalPowerConsumedByOthers + (template.powerRequired ?? 0)}", isError: true);
                    return; // Don't change status
                }
            }
        }
    }
    
    // If we reach here, the toggle is permissible
    tempUpdatedBuildings[buildingIndex] = OwnedBuilding(
        uniqueId: ownedBuilding.uniqueId,
        templateId: ownedBuilding.templateId,
        dinosaurUniqueIds: ownedBuilding.dinosaurUniqueIds,
        currentFoodLevel: ownedBuilding.currentFoodLevel,
        isOperational: newStatus,
    );
    
    _provider.setProviderState(
      ownedBuildings: tempUpdatedBuildings,
      doPersist: false, // Recalculate will persist
      doNotify: true,
    );
    
    _logToPark("${template.name} is now ${newStatus ? 'operational' : 'offline'}.", isError: !newStatus);
    _recalculateParkStats(); // This will update power grid and persist
  }


  void _updateBuildingOperationalStatusBasedOnPower() {
    int totalPowerGenerated = 0;
    int totalPowerRequiredByOperationalConsumers = 0;
    List<OwnedBuilding> currentBuildings = List.from(_provider.ownedBuildings); // Work on a mutable copy

    // First pass: ensure all power plants are considered for generation,
    // and sum up demand from all *currently* (potentially user-set) operational consumers.
    for (var building in currentBuildings) {
        final template = _provider.buildingTemplatesList.firstWhereOrNull((t) => t.id == building.templateId);
        if (template == null) continue;

        if (template.type == "power_plant" && building.isOperational) {
            totalPowerGenerated += template.powerOutput ?? 0;
        } else if (template.type != "power_plant" && building.isOperational) {
            totalPowerRequiredByOperationalConsumers += template.powerRequired ?? 0;
        }
    }
    
    bool changesMadeToOperationalStatus = false;
    if (totalPowerRequiredByOperationalConsumers > totalPowerGenerated) {
        _logToPark("Power shortage! Demand ($totalPowerRequiredByOperationalConsumers) exceeds supply ($totalPowerGenerated). Attempting to manage load...", isError: true);
        
        // Sort consumers by power requirement descending to turn off heaviest consumers first
        List<OwnedBuilding> consumersToPotentiallyTurnOff = currentBuildings
            .where((b) {
                final t = _provider.buildingTemplatesList.firstWhereOrNull((tmpl) => tmpl.id == b.templateId);
                return t?.type != "power_plant" && b.isOperational && (t?.powerRequired ?? 0) > 0;
            })
            .toList()
            ..sort((a, b) {
                final ta = _provider.buildingTemplatesList.firstWhere((t) => t.id == a.templateId);
                final tb = _provider.buildingTemplatesList.firstWhere((t) => t.id == b.templateId);
                return (tb.powerRequired ?? 0).compareTo(ta.powerRequired ?? 0);
            });

        int currentDemand = totalPowerRequiredByOperationalConsumers;
        for (var buildingToTurnOff in consumersToPotentiallyTurnOff) {
            if (currentDemand <= totalPowerGenerated) break; // Power balanced

            final template = _provider.buildingTemplatesList.firstWhere((t) => t.id == buildingToTurnOff.templateId);
            int buildingIndex = currentBuildings.indexWhere((b) => b.uniqueId == buildingToTurnOff.uniqueId);
            
            if (buildingIndex != -1 && currentBuildings[buildingIndex].isOperational) { // Check if it's still considered operational
                currentBuildings[buildingIndex] = OwnedBuilding(
                    uniqueId: buildingToTurnOff.uniqueId,
                    templateId: buildingToTurnOff.templateId,
                    dinosaurUniqueIds: buildingToTurnOff.dinosaurUniqueIds,
                    currentFoodLevel: buildingToTurnOff.currentFoodLevel,
                    isOperational: false, // Turn it off
                );
                currentDemand -= (template.powerRequired ?? 0);
                _logToPark("${template.name} turned offline due to power shortage.", isError: true);
                changesMadeToOperationalStatus = true;
            }
        }
        totalPowerRequiredByOperationalConsumers = currentDemand; 
    }

    // Update GameProvider's ParkManager with new power stats
    // And potentially update ownedBuildings if changes were made
    _provider.setProviderState(
        ownedBuildings: changesMadeToOperationalStatus ? currentBuildings : null, 
        parkManager: _provider.parkManager
            ..currentPowerGenerated = totalPowerGenerated
            ..currentPowerConsumed = totalPowerRequiredByOperationalConsumers,
        doPersist: true, // Persist if any building status or power calculation changed.
        doNotify: true 
    );
}


  void updateAllDinosaursStatus() {
    if (_provider.ownedDinosaurs.isEmpty) return;
    bool changed = false;

    final List<OwnedDinosaur> updatedDinos = _provider.ownedDinosaurs.map((dino) {
        final species = _provider.dinosaurSpeciesList.firstWhereOrNull((s) => s.id == dino.speciesId);
        if (species == null) return dino; // Should not happen

        OwnedDinosaur updatedDino = OwnedDinosaur.fromJson(dino.toJson()); // Create a mutable copy

        if (updatedDino.name.contains("(Incubating)")) {
            updatedDino.age += 1; // Increment incubation time (e.g., 1 unit per minute)
            // Check if incubation is complete
            if (updatedDino.age >= baseIncubationDuration) { 
                updatedDino.name = species.name; // Remove "(Incubating)"
                _logToPark("${species.name} has hatched!");
                updatedDino.age = 0; // Reset age to 0 for hatched dinos (or start actual aging)
                changed = true;
            }
            return updatedDino;
        }

        // For hatched dinosaurs:
        updatedDino.age +=1; // Age them up

        // Food decay
        updatedDino.currentFood = (updatedDino.currentFood - (_random.nextDouble() * 2 + 1)).clamp(0.0, 100.0); // Decay 1-3 food

        // Comfort calculation (simplified)
        double comfortImpact = 0;
        final enclosure = _provider.ownedBuildings.firstWhereOrNull((b) => b.dinosaurUniqueIds.contains(dino.uniqueId));
        
        if (enclosure != null) {
            final enclosureTemplate = _provider.buildingTemplatesList.firstWhereOrNull((t) => t.id == enclosure.templateId);
            if (enclosureTemplate != null) {
                final dinosInSameEnclosure = enclosure.dinosaurUniqueIds.length;
                // Social needs
                if (dinosInSameEnclosure < species.socialNeedsMin || dinosInSameEnclosure > species.socialNeedsMax) {
                    comfortImpact -= 5;
                } else {
                    comfortImpact += 2;
                }
                // Enclosure size (very basic check)
                if (enclosureTemplate.capacity != null && species.enclosureSizeNeeds * dinosInSameEnclosure > enclosureTemplate.capacity! * 5 /* arbitrary multiplier */) {
                     comfortImpact -= 3; // Overcrowded based on a simple capacity notion
                }
            }
             // Check food station linked to this enclosure (if any)
            final foodStation = _provider.ownedBuildings.firstWhereOrNull((b) {
                final fTemplate = _provider.buildingTemplatesList.firstWhereOrNull((ft) => ft.id == b.templateId);
                // This assumes a generic food station for now, or you'd link them
                return fTemplate?.type == "food_station" && b.isOperational;
            });
            if (foodStation != null && (foodStation.currentFoodLevel ?? 0) > 0) {
                // Consume food
                final int foodConsumed = _random.nextInt(5) + 1; // Consumes 1-5 food
                final newFoodStationLevel = (foodStation.currentFoodLevel ?? 0) - foodConsumed;
                 List<OwnedBuilding> tempBuildings = List.from(_provider.ownedBuildings);
                 int fsIndex = tempBuildings.indexWhere((b) => b.uniqueId == foodStation.uniqueId);
                 if (fsIndex != -1) {
                    tempBuildings[fsIndex] = OwnedBuilding(
                        uniqueId: foodStation.uniqueId,
                        templateId: foodStation.templateId,
                        dinosaurUniqueIds: foodStation.dinosaurUniqueIds,
                        isOperational: foodStation.isOperational,
                        currentFoodLevel: newFoodStationLevel.clamp(0, enclosureBaseFoodCapacity)
                    );
                    // This state change should ideally be batched with other dino updates
                     _provider.setProviderState(ownedBuildings: tempBuildings, doPersist: false, doNotify: false); // Notify at the end
                     changed = true;
                 }
                updatedDino.currentFood = (updatedDino.currentFood + foodConsumed * 5).clamp(0.0, 100.0); // food value per unit
            }


        } else {
            comfortImpact -= 10; // Not in an enclosure
        }

        // Food impact on comfort
        if (updatedDino.currentFood < 20) comfortImpact -= 10;
        else if (updatedDino.currentFood < 50) comfortImpact -= 5;
        else if (updatedDino.currentFood > 80) comfortImpact += 3;

        updatedDino.currentComfort = (updatedDino.currentComfort + comfortImpact).clamp(0.0, 100.0);

        // Health impact from low comfort or food
        if (updatedDino.currentComfort < species.comfortThreshold * 100 * 0.5) { // If comfort is less than half the threshold
            updatedDino.currentHealth = (updatedDino.currentHealth - 2).clamp(0.0, 100.0);
        }
        if (updatedDino.currentFood < 10) {
            updatedDino.currentHealth = (updatedDino.currentHealth - 3).clamp(0.0, 100.0);
        }

        if (dino.currentComfort != updatedDino.currentComfort || dino.currentFood != updatedDino.currentFood || dino.currentHealth != updatedDino.currentHealth || dino.name != updatedDino.name || dino.age != updatedDino.age) {
            changed = true;
        }
        return updatedDino;
    }).toList();

    if (changed) {
        _provider.setProviderState(ownedDinosaurs: updatedDinos, doPersist: true, doNotify: true);
        _recalculateParkStats(); // Dinosaur health/status might affect rating indirectly
    }
}



  void _recalculateParkStats() {
    _updateBuildingOperationalStatusBasedOnPower(); // Ensure operational statuses are up-to-date first

    int newParkRating = 0;
    int newIncomePerMinuteDollars = 0;
    int newOperationalCostPerMinuteDollars = 0;
    
    // Recalculate power generated and consumed based on the potentially updated operational statuses
    int currentPowerGenerated = 0;
    int currentPowerConsumed = 0;

    for (var ownedBuilding in _provider.ownedBuildings) { // Use the latest list from provider
      final template = _provider.buildingTemplatesList.firstWhereOrNull((t) => t.id == ownedBuilding.templateId);
      if (template != null && ownedBuilding.isOperational) { // Only count operational buildings
        newParkRating += template.parkRatingBoost ?? 0;
        newIncomePerMinuteDollars += template.incomePerMinuteDollars ?? 0;
        newOperationalCostPerMinuteDollars += template.operationalCostPerMinuteDollars ?? 0;
        
        if (template.type == "power_plant") {
            currentPowerGenerated += template.powerOutput ?? 0;
        } else {
            currentPowerConsumed += template.powerRequired ?? 0;
        }
      }
    }
    
    for (var ownedDino in _provider.ownedDinosaurs) {
        final species = _provider.dinosaurSpeciesList.firstWhereOrNull((s) => s.id == ownedDino.speciesId);
        if (species != null && !ownedDino.name.contains("(Incubating)")) { // Only count hatched dinos
            double ratingModifier = 1.0;
            if(ownedDino.currentComfort < species.comfortThreshold * 100) ratingModifier *= 0.5; // Penalty for low comfort
            if(ownedDino.currentHealth < 50) ratingModifier *= 0.7; // Penalty for low health
            newParkRating += (species.baseRating * ratingModifier).round();
        }
    }
    newParkRating = newParkRating.clamp(0, MAX_PARK_RATING_FOR_STARS * 2); 

    _provider.setProviderState(
      parkManager: ParkManager(
        parkRating: newParkRating,
        parkDollars: _provider.parkManager.parkDollars, 
        parkEnergy: _provider.playerEnergy, 
        maxParkEnergy: _provider.calculatedMaxEnergy, 
        incomePerMinuteDollars: newIncomePerMinuteDollars,
        operationalCostPerMinuteDollars: newOperationalCostPerMinuteDollars,
        currentPowerGenerated: currentPowerGenerated,
        currentPowerConsumed: currentPowerConsumed,
      ),
      doPersist: true, // Persist after recalculation
      doNotify: true,
    );
  }
  void recalculateParkStats(){ 
    _recalculateParkStats();
  }

  void skipOneMinute() {
    if (_provider.playerEnergy < SKIP_MINUTE_ENERGY_COST) {
        _logToPark("Not enough energy to fast forward time. Cost: $SKIP_MINUTE_ENERGY_COST⚡", isError: true);
        return;
    }

    // Deduct energy
    final newPlayerEnergy = _provider.playerEnergy - SKIP_MINUTE_ENERGY_COST;

    // Simulate one minute of park updates
    updateAllDinosaursStatus(); // Update dinosaur needs & incubation
    
    // Recalculate park stats immediately after dino status update which might affect income/costs
    // _recalculateParkStats() already calls _updateBuildingOperationalStatusBasedOnPower
    // and then updates the ParkManager instance with new income/costs based on *operational* buildings.
    // So, we first get the income/cost *before* potentially changing dino states for this skipped minute.
    int incomeThisSkippedMinute = _provider.parkManager.incomePerMinuteDollars;
    int costsThisSkippedMinute = _provider.parkManager.operationalCostPerMinuteDollars;

    double newParkDollars = _provider.parkManager.parkDollars + incomeThisSkippedMinute - costsThisSkippedMinute + SKIP_MINUTE_PARK_DOLLAR_BONUS;

    _provider.setProviderState(
        playerEnergy: newPlayerEnergy,
        parkManager: _provider.parkManager..parkDollars = newParkDollars.isNegative ? 0 : newParkDollars,
        // ownedDinosaurs and ownedBuildings are updated within their respective methods called by updateAllDinosaursStatus or _recalculateParkStats
        doPersist: true,
        doNotify: true
    );
    
    // Final recalculate and log after all changes for the skipped minute are applied.
    // This ensures ParkManager's generated/consumed power is also accurate.
    _recalculateParkStats(); 
    _logToPark("Fast forwarded 1 minute. Income: \$${incomeThisSkippedMinute}, Costs: \$${costsThisSkippedMinute}. Bonus: \$${SKIP_MINUTE_PARK_DOLLAR_BONUS}. Energy Cost: ${SKIP_MINUTE_ENERGY_COST}⚡");
  }

}