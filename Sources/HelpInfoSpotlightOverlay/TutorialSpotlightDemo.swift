import SwiftUI

#if DEBUG

/**
 Originally based on Artem Mirzabekian's repo -- https://github.com/Livsy90/TutorialSpotlight
 */
struct TutorialSpotlightDemo: View {
  @Environment(\.colorScheme) var colorScheme

  enum Step: CaseIterable, HelpInfoProvider {
    case profile
    case travelPlanner
    case filters
    case budgetFilter
    case familyFilter
    case foodFilter
    case showSheet
    case pastTrips
    case checkout

    var title: LocalizedStringKey {
      switch self {
      case .profile: "Profile"
      case .travelPlanner: "Travel Planner"
      case .filters: "Filters"
      case .budgetFilter: "Budget"
      case .familyFilter: "Family"
      case .foodFilter: "Food"
      case .showSheet: "Plan Summary"
      case .checkout: "Checkout"
      case .pastTrips: "Past Trips"
      }
    }

    var text: LocalizedStringKey {
      switch self {
      case .profile:
"""
Here the user quickly gets to their profile and account settings.
"""
      case .travelPlanner:
"""
This is a test. \
This is a test. \
This is a test.
This is a test.
"""
      case .filters:
"""
This block manages filters.
It's usually the second step in onboarding.
"""
      case .budgetFilter:
"""
Apply the 'Budget' smart filter.
"""
      case .familyFilter:
"""
Apply the 'Family' smart filter. Do some special processing when activated.
"""
      case .foodFilter:
"""
Apply the 'Food' smart filter. Nothing special.
"""
      case .showSheet:
"""
Show the plan summary.
"""
      case .checkout:
"""
The button completes the scenario. The final step may lead to payment or confirmation.
"""
      case .pastTrips:
"""
List of previous trips that have been taken.
"""
      }
    }
  }

  @State private var selection: Step?
  @State private var showSheet: Bool = false

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 24) {
          VStack(alignment: .leading, spacing: 12) {
            Text("Travel Planner")
              .font(.largeTitle.bold())

            Text("Build a trip, fine-tune filters, and finish booking in a couple of taps.")
              .foregroundStyle(.secondary)

            HStack(spacing: 12) {
              statCard(title: "12", subtitle: "Routes")
              statCard(title: "5", subtitle: "Cities")
              statCard(title: "3", subtitle: "Days")
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)

          filterPanel
            .helpInfoViewTag(.filters)

          Button("Show Sheet") { showSheet.toggle() }
            .helpInfoViewTag(.showSheet)
        }
        .helpInfoViewTag(.travelPlanner)
        .padding(24)
        pastTravel
          .helpInfoViewTag(.pastTrips)
          .padding(24)
      }
      .toolbar {
        ToolbarItem(placement: .automatic) {
          profileButton
            .helpInfoViewTag(.profile)
        }
        ToolbarItem(placement: .automatic) {
          Button {
            selection = .profile
          } label: {
            Image(systemName: "questionmark.circle")
          }
        }
      }
      .safeAreaInset(edge: .bottom) {
        checkoutButton
          .helpInfoViewTag(.checkout)
          .padding()
      }
    }
    .sheet(isPresented: $showSheet, onDismiss: {
      self.selection = nil
    }, content: {
      SheetSpotlightDemo()
    })
    .preferredColorScheme(colorScheme)
    .helpInfoSpotlightOverlay(
      selection: $selection,
      orderedIDs: Step.allCases,
      windowedMode: .useCustomWindow,
      overlay: helpInfoOverlay
    )
  }

  private var profileButton: some View {
    Button {
    } label: {
      Image(systemName: "person.crop.circle.fill")
    }
  }

  private var filterPanel: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Smart Filters")
        .font(.headline)

      HStack(spacing: 10) {
        chip("Budget")
          .helpInfoViewTag(.budgetFilter)
        chip("Family")
          .helpInfoViewTag(.familyFilter)
        chip("Food")
          .helpInfoViewTag(.foodFilter)
      }

      HStack(spacing: 14) {
        filterMetric(title: "Price", value: "$420")
        filterMetric(title: "Rating", value: "4.8")
        filterMetric(title: "Transit", value: "18 min")
      }
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.tertiary, in: .rect(cornerRadius: 28))
  }

  private var pastTravel: some View {
    let columns = [
      GridItem(alignment: .leading),
      GridItem(alignment: .leading),
      GridItem(.fixed(40), alignment: .leading),
    ]

    return VStack(alignment: .leading, spacing: 14) {
      Text("Past Travel")
        .font(.headline)

      LazyVGrid(columns: columns) {
        Section {
          GridRow {
            Text("Isle of Man")
            Text("$123")
            Text("1.3")
          }
          GridRow {
            Text("Bermuda")
            Text("$12,383")
            Text("5.0")
          }
          GridRow {
            Text("Saturn")
            Text("$98,334,341")
            Text("9.0")
          }
          GridRow {
            Text("Fargo")
            Text("$824")
            Text("3.2")
          }
          GridRow {
            Text("Mar-a-Lago")
            Text("$33,234")
            Text("0.0")
          }
        } header: {
          LazyVGrid(columns: columns, spacing: 0) {
            Text("Name")
            Text("Price")
            Text("Rating")
          }
        }
        .font(.footnote)
      }
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.tertiary, in: .rect(cornerRadius: 28))
  }

  private var checkoutButton: some View {
    Button {
      selection = .checkout
    } label: {
      HStack {
        Text("Continue")
        Spacer()
        Image(systemName: "arrow.right")
      }
      .font(.headline)
      .foregroundStyle(.white)
      .padding(.horizontal, 22)
      .padding(.vertical, 20)
      .frame(maxWidth: .infinity)
      .background(
        LinearGradient(
          colors: [.indigo, .cyan],
          startPoint: .leading,
          endPoint: .trailing
        ),
        in: .rect(cornerRadius: 24)
      )
    }
    .buttonStyle(.plain)
  }

  private func statCard(
    title: String,
    subtitle: String
  ) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title)
        .font(.title3.bold())
        .foregroundStyle(.orange)
      Text(subtitle)
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.secondary.opacity(0.3), in: .rect(cornerRadius: 12))
  }

  private func chip(_ title: String) -> some View {
    Text(title)
      .font(.subheadline.weight(.semibold))
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(.blue.opacity(0.30), in: Capsule())
  }

  private func filterMetric(
    title: String,
    value: String
  ) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .font(.caption)
        .foregroundStyle(.secondary)
      Text(value)
        .font(.headline)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct SheetSpotlightDemo: View {
  @Environment(\.colorScheme) var colorScheme

  enum Step: CaseIterable, HelpInfoProvider {
    case title
    case action

    var title: LocalizedStringKey {
      switch self {
      case .title: "Sheet Header"
      case .action: "Primary Action"
      }
    }

    var text: LocalizedStringKey {
      switch self {
      case .title: "This title explains the purpose of the modal flow."
      case .action: "This button confirms the choice and closes the scenario."
      }
    }
  }

  @Environment(\.dismiss) private var dismiss
  @State private var selection: Step?

  var body: some View {
    Form {
      VStack(alignment: .leading, spacing: 24) {
        VStack(alignment: .leading, spacing: 12) {
          Text("Plan Summary")
            .font(.title2.bold())
            .helpInfoViewTag(.title)

          Text("Review the details in the sheet before confirming the selection.")
            .foregroundStyle(.secondary)

          Button("Start tutorial") {
            selection = .title
          }
        }

        VStack(spacing: 14) {
          summaryRow(title: "Destination", value: "Lisbon")
          summaryRow(title: "Dates", value: "May 12 - May 16")
          summaryRow(title: "Guests", value: "2 adults")
        }
        .padding(18)

        Button {
          dismiss()
        } label: {
          Text("Confirm")
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(.blue.gradient, in: .rect(cornerRadius: 18))
        }
        .helpInfoViewTag(.action)
      }
      .buttonStyle(.plain)
    }
    .background(.background)
    .helpInfoSpotlightOverlay(
      selection: $selection,
      orderedIDs: [Step.title, .action],
      windowedMode: .useCustomWindow,
      overlay: helpInfoOverlay
    )
    .presentationDetents([.medium, .large])
  }

  private func summaryRow(title: String, value: String) -> some View {
    HStack {
      Text(title)
        .foregroundStyle(.secondary)
      Spacer()
      Text(value)
        .fontWeight(.semibold)
    }
  }
}

// Extensions to support auto-completion of `Step` enum values.
extension View {
  fileprivate func helpInfoViewTag(_ id: TutorialSpotlightDemo.Step) -> some View {
    helpInfoViewTag(id: id)
  }
  fileprivate func helpInfoViewTag(_ id: SheetSpotlightDemo.Step) -> some View {
    helpInfoViewTag(id: id)
  }
}

#Preview {

#if os(macOS)

  TutorialSpotlightDemo()
    .frame(width: 800, height: 600)

#else

  TutorialSpotlightDemo()

#endif

}

#endif // DEBUG
